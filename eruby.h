/*
 * $Id$
 * Copyright (C) 2000  ZetaBITS, Inc.
 * Copyright (C) 2000  Information-technology Promotion Agency, Japan
 */

#ifndef ERUBY_H
#define ERUBY_H

#define ERUBY_VERSION "1.0.6"

#define ERUBY_MIME_TYPE "application/x-httpd-eruby"

enum eruby_compile_status {
    ERUBY_OK = 0,
    ERUBY_MISSING_END_DELIMITER,
    ERUBY_INVALID_OPTION,
    ERUBY_SYSTEM_ERROR
};

enum eruby_mode {
    MODE_UNKNOWN,
    MODE_FILTER,
    MODE_CGI,
    MODE_NPHCGI
};

extern char *eruby_filename;
extern int eruby_mode;
extern int eruby_noheader;
extern int eruby_sync;
extern VALUE eruby_charset;
extern VALUE eruby_default_charset;
#define ERUBY_CHARSET RSTRING_PTR(eruby_charset)

const char *eruby_version();
int eruby_parse_options(int argc, char **argv, int *optind);
VALUE eruby_compiler_new();
VALUE eruby_compiler_set_sourcefile(VALUE self, VALUE filename);
VALUE eruby_compiler_compile_file(VALUE self, VALUE file);
VALUE eruby_compiler_compile_string(VALUE self, VALUE s);
VALUE eruby_load(char *filename, int wrap, int *state);
void eruby_init();

/* for compatibility with ruby 1.9 */
#ifndef RARRAY_LEN
# define RARRAY_LEN(ary) (RARRAY(ary)->len)
#endif
#ifndef RARRAY_PTR
# define RARRAY_PTR(ary) (RARRAY(ary)->ptr)
#endif
#ifndef RSTRING_LEN
# define RSTRING_LEN(str) (RSTRING(str)->len)
#endif
#ifndef RSTRING_PTR
# define RSTRING_PTR(str) (RSTRING(str)->ptr)
#endif

#endif /* ERUBY_H */

/*
 * Local variables:
 * mode: C
 * tab-width: 8
 * End:
 */
