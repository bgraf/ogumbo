/**
 * Ogumbo - OCaml wrapper for the Gumbo HTML5 parser.
 *
 *
 * Authors:
 *    Benjamin Graf     (bgraf@uni-osnabrueck.de)
 */

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>

#include <gumbo.h>

#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

/* # Chapter 1 - A container for parser output.
 *
 *
 */

struct container {
  size_t ref_count;
  char *source_buffer;
  size_t source_buffer_size;
  GumboOutput *output;
  GumboOptions options;
};


static struct container *container_init(
    struct container *container,
    char *source_buffer,
    size_t source_buffer_size,
    GumboOutput *output,
    GumboOptions const * options)
{
  if (container == NULL)
    return NULL;

  assert(container != NULL);
  assert(output != NULL);
  assert(source_buffer != NULL);

  container->ref_count = 0;

  container->output = output;
  
  container->source_buffer = source_buffer;
  container->source_buffer_size = source_buffer_size;

  if (options == NULL)
    options = &kGumboDefaultOptions;
  memcpy(&container->options, options, sizeof(GumboOptions));

  return container;
}


static void container_deinit(struct container *container) {
  if (container == NULL)
    return;

  if (container->output != NULL)
    gumbo_destroy_output(&container->options, container->output);
  if (container->source_buffer != NULL)
    free(container->source_buffer);
}


static struct container *container_new(
    char *source_buffer,
    size_t source_buffer_size,
    GumboOutput *output,
    GumboOptions const * options)
{
  assert(output != NULL);

  return container_init(malloc(sizeof(struct container)),
                        source_buffer, source_buffer_size,
                        output, options);
}
                             

static void container_del(struct container *container)
{
  if (container != NULL) {
    container_deinit(container);
    free(container);
  }
}


static void container_incref(struct container *container) {
  assert(container != NULL);
  container->ref_count++;
}


static void container_decref(struct container *container) {
  assert(container != NULL);

  if (container->ref_count > 0)
    container->ref_count--;

  if (container->ref_count == 0)
    container_del(container);
}


/* # Chapter 2 - Internal values
 *
 * Any ocaml function returning an abstract type X.t will actually return
 * a structure containing two pointers.
 * One pointing to a container structure holding a reference count and
 * gumbo output and one pointing to the actual X.t.
 *
 * For a plain gumbo output object as returned by the `parse_*` functions,
 * the second pointer will be NULL.
 *
 * ## Example
 *
 * Given a the function `Node.parent : Node.t -> Node.t`.
 * It will take and produce a structure `ptr_pair` as follows:
 *
 *                +--------------------+--------+
 *                | struct container * | void * |
 *                +--------------------+--------+
 *                   |                      |  
 *    +-----------+  |                      |  +------+   
 *    | Container |<-'                      `->| Node |
 *    +-----------+                            +------+
 *              |        +-------------+          |
 *              `------->| GumboOutput |<---------'
 *                       +-------------+
 */

struct ptr_pair {
  struct container *container;
  void *pointer;
};


static struct ptr_pair *ptr_pair_init(struct ptr_pair *pair,
                                      struct container *container,
                                      void *pointer)
{
  if (pair == NULL)
    return NULL;

  assert(container != NULL);

  container_incref(container);

  pair->container = container;
  pair->pointer   = pointer;

  return pair;
}


#define ptr_pair_val(v) ((struct ptr_pair *) Data_custom_val(v))


static void ptr_pair_value_finalize(value v) {
  struct ptr_pair *pair = ptr_pair_val(v);
  container_decref(pair->container);
}


static int ptr_pair_value_compare(value v1, value v2) {
  const size_t p1 = (size_t)ptr_pair_val(v1)->pointer;
  const size_t p2 = (size_t)ptr_pair_val(v2)->pointer;

  return p1 == p2 ? 0 : (p1 > p2 ? 1 : -1);
}


static intnat ptr_pair_value_hash(value v) {
  return (size_t)ptr_pair_val(v)->pointer;
}


static struct custom_operations ptr_pair_value_operations = {
  "bgraf.ogumbo",
  ptr_pair_value_finalize,
  ptr_pair_value_compare,
  ptr_pair_value_hash,
  custom_serialize_default,
  custom_deserialize_default
};


static value ptr_pair_value_new(struct container *container,
                                void *pointer)
{
  value v = caml_alloc_custom(&ptr_pair_value_operations, 
                              sizeof(struct ptr_pair),
                              0, 1);

  ptr_pair_init(ptr_pair_val(v), container, pointer);

  return v;
}

/* # Chapter 3 - Gluing together
 *
 *
 *
 */

enum source_position_field {
  SOURCE_POSITION_FIELD_LINE = 0,
  SOURCE_POSITION_FIELD_COLUMN,
  SOURCE_POSITION_FIELD_OFFSET
};

/**
 * Make ocaml value of source position.
 * @param   source_position   The source position.
 * @return  Ocaml value containing the source position.
 */
static value value_of_source_pos(GumboSourcePosition *source_position) {
  value result = caml_alloc(3, 0);
  
  Store_field(result, SOURCE_POSITION_FIELD_LINE,
              Val_long(source_position->line));
  Store_field(result, SOURCE_POSITION_FIELD_COLUMN,
              Val_long(source_position->column));
  Store_field(result, SOURCE_POSITION_FIELD_OFFSET,
              Val_long(source_position->offset));

  return result;
}

/**
 * Make ocaml value of string piece.
 * @param   string_piece  The string piece.
 * @return  Ocaml string containing the bytes referenced by the string piece.
 */
static value value_of_string_piece(GumboStringPiece *string_piece) {
  size_t len = string_piece->length;
  value result = caml_alloc_string(len);

  for (size_t i = 0; i < len; i++)
    Byte(result, i) = string_piece->data[i];

  return result;
}

/**
 * Make ocaml list of gumbo vector.
 * @param   vector      The vector.
 * @param   container   The container associated with the vector entries.
 * @return  Ocaml list containing the vector's entries.
 */
static value value_of_vector(GumboVector *vector,
                             struct container *container)
{
  value current = Val_int(0);

  if (vector->data == NULL)
    return current;

  const size_t n = vector->length;
  for (size_t i = 0; i < n; i++) {
    value next = caml_alloc_tuple(2);
    Store_field(next, 0, ptr_pair_value_new(container, vector->data[n-i-1]));
    Store_field(next, 1, current);

    current = next;
  }

  return current;
}


#define ptr_pair_value_dup(v,p)\
  (ptr_pair_value_new(ptr_pair_val(v)->container, p))

value ogumbo_parse(value ostr)
{
  CAMLparam1(ostr);

  char *source_buffer = String_val(ostr);
  size_t source_buffer_size = caml_string_length(ostr);

  char *source_buffer_copy = malloc((source_buffer_size + 1) * sizeof(char));
  memcpy(source_buffer_copy, source_buffer, source_buffer_size+1);

  GumboOutput *output = gumbo_parse_with_options(&kGumboDefaultOptions,
                                                 source_buffer_copy,
                                                 source_buffer_size);

  struct container *container = container_new(source_buffer_copy,
                                              source_buffer_size,
                                              output,
                                              &kGumboDefaultOptions);

  CAMLreturn(ptr_pair_value_new(container, NULL));
}


/* Document */

value ogumbo_output_document(value ooutput) {
  CAMLparam1(ooutput);
  CAMLlocal1(result);

  result = ptr_pair_value_dup(ooutput, NULL);
  // result = ptr_pair_value_new(ptr_pair_val(ooutput)->container, NULL);
  
  CAMLreturn(result);
}

value ogumbo_output_document_node(value ooutput) {
  CAMLparam1(ooutput);
  CAMLlocal1(result);

  struct ptr_pair *pair = ptr_pair_val(ooutput);

  result = ptr_pair_value_new(pair->container,
                              pair->container->output->document);
  
  CAMLreturn(result);
}

value ogumbo_output_root(value ooutput) {
  CAMLparam1(ooutput);
  CAMLlocal1(result);

  struct ptr_pair *pair = ptr_pair_val(ooutput);

  result = ptr_pair_value_new(pair->container,
                              pair->container->output->root);
  
  CAMLreturn(result);
}

value ogumbo_document_has_doctype(value odocument) {
  CAMLparam1(odocument);
  bool has_doctype =
    ptr_pair_val(odocument)->container->output->document->v.document.has_doctype;
  CAMLreturn(Val_bool(has_doctype));
}

value ogumbo_document_name(value odocument) {
  CAMLparam1(odocument);
  CAMLlocal1(result);

  const struct ptr_pair *pair = ptr_pair_val(odocument);
  result = caml_copy_string(
      pair->container->output->document->v.document.name);
  CAMLreturn(result);
}

value ogumbo_document_public_identifier(value odocument) {
  CAMLparam1(odocument);
  CAMLlocal1(result);

  const struct ptr_pair *pair = ptr_pair_val(odocument);
  result = caml_copy_string(
      pair->container->output->document->v.document.public_identifier);

  CAMLreturn(result);
}

value ogumbo_document_system_identifier(value odocument) {
  CAMLparam1(odocument);
  CAMLlocal1(result);

  const struct ptr_pair *pair = ptr_pair_val(odocument);
  result = caml_copy_string(
      pair->container->output->document->v.document.system_identifier);

  CAMLreturn(result);
}

value ogumbo_document_children(value odocument) {
  CAMLparam1(odocument);
  CAMLlocal1(result);

  const struct ptr_pair *pair = ptr_pair_val(odocument);
  
  result = value_of_vector(
      &pair->container->output->document->v.document.children,
      pair->container);

  CAMLreturn(result);
}

/* Node */

value ogumbo_node_parent(value onode) {
  CAMLparam1(onode);
  CAMLlocal1(result);  

  /* This function will return 'a option = Some 'a | None
   * with None    -> Val_int(0)
   *      Some x  -> Block(tag=0, Field(0 = x))
   */

  struct ptr_pair *pair = ptr_pair_val(onode);
  GumboNode *parent = ((GumboNode*)pair->pointer)->parent;

  if (parent == NULL) {
    /* => None */
    result = Val_int(0);
  } else {
    /* => Some (parent) */
    result = caml_alloc(1, 0);
    Store_field(result, 0, ptr_pair_value_new(pair->container, parent));
  }

  CAMLreturn(result);
}

value ogumbo_node_index(value onode) {
  CAMLparam1(onode);
  struct ptr_pair *pair = ptr_pair_val(onode);
  long int index = ((GumboNode*)pair->pointer)->index_within_parent;
  CAMLreturn(Val_long(index));
}

value ogumbo_node_value(value onode) {
  CAMLparam1(onode);
  CAMLlocal1(result);

  struct ptr_pair *pair = ptr_pair_val(onode);
  GumboNode *node = (GumboNode*)pair->pointer;

  void *result_ptr = NULL;

  switch (node->type) {
  case GUMBO_NODE_DOCUMENT:
    result_ptr = &node->v.document;
    break;
  case GUMBO_NODE_ELEMENT:
  case GUMBO_NODE_TEMPLATE:
    result_ptr = &node->v.element;
    break;
  default:
    result_ptr = &node->v.text;
    break;
  }

  result = caml_alloc(1, node->type);
  Store_field(result, 0, ptr_pair_value_new(pair->container, result_ptr));

  CAMLreturn(result);
}


/* Element */

value ogumbo_elem_tag(value oelem) {
  CAMLparam1(oelem);

  GumboElement *elem = ptr_pair_val(oelem)->pointer;

  CAMLreturn(Val_int(elem->tag));
}

value ogumbo_elem_namespace(value oelem) {
  CAMLparam1(oelem);

  GumboElement *elem = ptr_pair_val(oelem)->pointer;

  CAMLreturn(Val_int(elem->tag_namespace));
}

value ogumbo_elem_original_tag(value oelem) {
  CAMLparam1(oelem);
  CAMLlocal1(result);
  
  GumboElement *elem = ptr_pair_val(oelem)->pointer;
  result = value_of_string_piece(&elem->original_tag);

  CAMLreturn(result);
}

value ogumbo_elem_original_end_tag(value oelem) {
  CAMLparam1(oelem);
  CAMLlocal1(result);

  GumboElement *elem = ptr_pair_val(oelem)->pointer;
  result = value_of_string_piece(&elem->original_end_tag);

  CAMLreturn(result);
}

value ogumbo_elem_start_pos(value oelem) {
  CAMLparam1(oelem);
  CAMLlocal1(result);
  GumboElement *elem = ptr_pair_val(oelem)->pointer;
  result = value_of_source_pos(&elem->start_pos);
  CAMLreturn(result);
}

value ogumbo_elem_end_pos(value oelem) {
  CAMLparam1(oelem);
  CAMLlocal1(result);
  GumboElement *elem = ptr_pair_val(oelem)->pointer;
  result = value_of_source_pos(&elem->end_pos);
  CAMLreturn(result);
}

value ogumbo_elem_children(value oelem) {
  CAMLparam1(oelem);
  CAMLlocal1(result);

  struct ptr_pair *pair = ptr_pair_val(oelem);
  GumboElement *elem = pair->pointer;
  result = value_of_vector(&elem->children, pair->container);

  CAMLreturn(result);
}

value ogumbo_elem_attributes(value oelem) {
  CAMLparam1(oelem);
  CAMLlocal1(result);

  struct ptr_pair *pair = ptr_pair_val(oelem);
  GumboElement *elem = pair->pointer;
  result = value_of_vector(&elem->attributes, pair->container);

  CAMLreturn(result);
}


/* Tag */

value ogumbo_tag_to_string(value otag) {
  CAMLparam1(otag);
  CAMLreturn(caml_copy_string(gumbo_normalized_tagname(Int_val(otag))));
}

/* Text */

value ogumbo_text_text(value otext) {
  CAMLparam1(otext);
  GumboText *text = ptr_pair_val(otext)->pointer;
  CAMLreturn(caml_copy_string(text->text));
}

value ogumbo_text_original_text(value otext) {
  CAMLparam1(otext);
  CAMLlocal1(result);
  GumboText *text = ptr_pair_val(otext)->pointer;
  result = value_of_string_piece(&text->original_text);
  CAMLreturn(result);
}

value ogumbo_text_start_pos(value otext) {
  CAMLparam1(otext);
  CAMLlocal1(result);
  GumboText *text = ptr_pair_val(otext)->pointer;
  result = value_of_source_pos(&text->start_pos);
  CAMLreturn(result);
}


/* Attribute */

value ogumbo_attr_namespace(value oattr) {
  CAMLparam1(oattr);
  CAMLreturn(Val_unit);
}

value ogumbo_attr_name(value oattr) {
  CAMLparam1(oattr);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  CAMLreturn(caml_copy_string(attr->name));
}

value ogumbo_attr_original_name(value oattr) {
  CAMLparam1(oattr);
  CAMLlocal1(result);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  result = value_of_string_piece(&attr->original_name);
  CAMLreturn(result);
}

value ogumbo_attr_value(value oattr) {
  CAMLparam1(oattr);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  CAMLreturn(caml_copy_string(attr->value));
}

value ogumbo_attr_original_value(value oattr) {
  CAMLparam1(oattr);
  CAMLlocal1(result);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  result = value_of_string_piece(&attr->original_value);
  CAMLreturn(result);
}

value ogumbo_attr_name_start(value oattr) {
  CAMLparam1(oattr);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  CAMLreturn(value_of_source_pos(&attr->name_start));
}

value ogumbo_attr_name_end(value oattr) {
  CAMLparam1(oattr);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  CAMLreturn(value_of_source_pos(&attr->name_end));
}

value ogumbo_attr_value_start(value oattr) {
  CAMLparam1(oattr);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  CAMLreturn(value_of_source_pos(&attr->value_start));
}

value ogumbo_attr_value_end(value oattr) {
  CAMLparam1(oattr);
  GumboAttribute *attr = ptr_pair_val(oattr)->pointer;
  CAMLreturn(value_of_source_pos(&attr->value_end));
}
