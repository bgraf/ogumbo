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
  printf("initializing container\n");
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
  printf("freeing container\n");
  if (container != NULL) {
    container_deinit(container);
    free(container);
  }
}


static void container_incref(struct container *container) {
  printf("incref\n");
  assert(container != NULL);
  container->ref_count++;
}


static void container_decref(struct container *container) {
  printf("decref\n");
  assert(container != NULL);

  printf("container decref\n");
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
  printf("finalize!\n");
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

  printf("o->root = %p\n", output->root);
  printf("o->root->parent = %p\n", output->root->parent);
  printf("o->doc  = %p\n", output->document);
  printf("o->doc->parent  = %p\n", output->document->parent);

  struct container *container = container_new(source_buffer_copy,
                                              source_buffer_size,
                                              output,
                                              &kGumboDefaultOptions);

  CAMLreturn(ptr_pair_value_new(container, NULL));
}

value ogumbo_output_document(value ooutput) {
  CAMLparam1(ooutput);
  CAMLlocal1(result);

  result = ptr_pair_value_dup(ooutput, NULL);
  // result = ptr_pair_value_new(ptr_pair_val(ooutput)->container, NULL);
  
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
