/*
 * $Id$
 * Copyright (C) 2000  ZetaBITS, Inc.
 * Copyright (C) 2000  Information-technology Promotion Agency, Japan
 * Copyright (C) 2000  Shugo Maeda <shugo@modruby.net>
 *
 * This file is part of eruby.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA
 */

#include <ctype.h>
#include <time.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include "ruby.h"
#include "re.h"
#include "regex.h"
#include "version.h"

#include "eruby.h"
#include "eruby_logo.h"

EXTERN VALUE ruby_errinfo;
EXTERN VALUE rb_stdout;
#if RUBY_VERSION_CODE < 180
EXTERN VALUE rb_defout;
#endif
EXTERN VALUE rb_load_path;

/* copied from eval.c */
#define TAG_RETURN	0x1
#define TAG_BREAK	0x2
#define TAG_NEXT	0x3
#define TAG_RETRY	0x4
#define TAG_REDO	0x5
#define TAG_RAISE	0x6
#define TAG_THROW	0x7
#define TAG_FATAL	0x8
#define TAG_MASK	0xf

static void *eruby_xmalloc(size_t size)
{
    void *ptr;

    if ((ptr = malloc(size)) == NULL) {
        fprintf(stderr, "failed to allocate memory\n");
        exit(1);
    }
    return ptr;
}

static void write_escaping_html(FILE *out, char *str, int len)
{
    int i;
    for (i = 0; i < len; i++) {
	switch (str[i]) {
	case '&':
	    fputs("&amp;", out);
	    break;
	case '<':
	    fputs("&lt;", out);
	    break;
	case '>':
	    fputs("&gt;", out);
	    break;
	case '"':
	    fputs("&quot;", out);
	    break;
	default:
	    putc(str[i], out);
	    break;
	}
    }
}

static void error_pos(FILE *out, int cgi)
{
    char buff[BUFSIZ];
    ID last_func = rb_frame_last_func();

    if (ruby_sourcefile) {
	if (last_func) {
	    snprintf(buff, BUFSIZ, "%s:%d:in `%s'", ruby_sourcefile, ruby_sourceline,
		     rb_id2name(last_func));
	}
	else {
	    snprintf(buff, BUFSIZ, "%s:%d", ruby_sourcefile, ruby_sourceline);
	}
	if (cgi)
	    write_escaping_html(out, buff, strlen(buff));
	else
	    fputs(buff, out);
    }
}

static void exception_print(FILE *out, int cgi)
{
    VALUE errat;
    VALUE eclass;
    VALUE einfo;

    if (NIL_P(ruby_errinfo)) return;

    errat = rb_funcall(ruby_errinfo, rb_intern("backtrace"), 0);
    if (!NIL_P(errat)) {
	VALUE mesg = RARRAY(errat)->ptr[0];

	if (NIL_P(mesg)) {
	    error_pos(out, cgi);
	}
	else {
	    if (cgi)
		write_escaping_html(out, RSTRING(mesg)->ptr, RSTRING(mesg)->len);
	    else
		fwrite(RSTRING(mesg)->ptr, 1, RSTRING(mesg)->len, out);
	}
    }

    eclass = CLASS_OF(ruby_errinfo);
    einfo = rb_obj_as_string(ruby_errinfo);
    if (eclass == rb_eRuntimeError && RSTRING(einfo)->len == 0) {
	fprintf(out, ": unhandled exception\n");
    }
    else {
	VALUE epath;

	epath = rb_class_path(eclass);
	if (RSTRING(einfo)->len == 0) {
	    fprintf(out, ": ");
	    if (cgi)
		write_escaping_html(out, RSTRING(epath)->ptr, RSTRING(epath)->len);
	    else
		fwrite(RSTRING(epath)->ptr, 1, RSTRING(epath)->len, out);
	    if (cgi)
		fprintf(out, "<br>\n");
	    else
		fprintf(out, "\n");
	}
	else {
	    char *tail  = 0;
	    int len = RSTRING(einfo)->len;

	    if (RSTRING(epath)->ptr[0] == '#') epath = 0;
	    if ((tail = strchr(RSTRING(einfo)->ptr, '\n')) != NULL) {
		len = tail - RSTRING(einfo)->ptr;
		tail++;		/* skip newline */
	    }
	    fprintf(out, ": ");
	    if (cgi)
		write_escaping_html(out, RSTRING(einfo)->ptr, len);
	    else
		fwrite(RSTRING(einfo)->ptr, 1, len, out);
	    if (epath) {
		fprintf(out, " (");
		if (cgi)
		    write_escaping_html(out, RSTRING(epath)->ptr, RSTRING(epath)->len);
		else
		    fwrite(RSTRING(epath)->ptr, 1, RSTRING(epath)->len, out);
		if (cgi)
		    fprintf(out, ")<br>\n");
		else
		    fprintf(out, ")\n");
	    }
	    if (tail) {
		if (cgi)
		    write_escaping_html(out, tail, RSTRING(einfo)->len - len - 1);
		else
		    fwrite(tail, 1, RSTRING(einfo)->len - len - 1, out);
		if (cgi)
		    fprintf(out, "<br>\n");
		else
		    fprintf(out, "\n");
	    }
	}
    }

    if (!NIL_P(errat)) {
	int i;
	struct RArray *ep = RARRAY(errat);

#define TRACE_MAX (TRACE_HEAD+TRACE_TAIL+5)
#define TRACE_HEAD 8
#define TRACE_TAIL 5

	rb_ary_pop(errat);
	ep = RARRAY(errat);
	for (i=1; i<ep->len; i++) {
	    if (TYPE(ep->ptr[i]) == T_STRING) {
		if (cgi) {
		    fprintf(out, "<div class=\"backtrace\">from ");
		    write_escaping_html(out,
					RSTRING(ep->ptr[i])->ptr,
					RSTRING(ep->ptr[i])->len);
		}
		else {
		    fprintf(out, "        from ");
		    fwrite(RSTRING(ep->ptr[i])->ptr, 1,
			   RSTRING(ep->ptr[i])->len, out);
		}
		if (cgi)
		    fprintf(out, "<br></div>\n");
		else
		    fprintf(out, "\n");
	    }
	    if (i == TRACE_HEAD && ep->len > TRACE_MAX) {
		char buff[BUFSIZ];
		if (cgi)
		    snprintf(buff, BUFSIZ,
			     "<div class=\"backtrace\">... %ld levels...\n",
			     ep->len - TRACE_HEAD - TRACE_TAIL);
		else
		    snprintf(buff, BUFSIZ, "         ... %ld levels...<br></div>\n",
			     ep->len - TRACE_HEAD - TRACE_TAIL);
		if (cgi)
		    write_escaping_html(out, buff, strlen(buff));
		else
		    fputs(buff, out);
		i = ep->len - TRACE_TAIL;
	    }
	}
    }
}

static void print_generated_code(FILE *out, VALUE code, int cgi)
{
    if (cgi) {
	fprintf(out, "<tr><th id=\"code\">\n");
	fprintf(out, "GENERATED CODE\n");
	fprintf(out, "</th></tr>\n");
	fprintf(out, "<tr><td headers=\"code\">\n");
	fprintf(out, "<pre><code>\n");
    }
    else {
	fprintf(out, "--- generated code ---\n");
    }

    if (cgi) {
	write_escaping_html(out, RSTRING(code)->ptr, RSTRING(code)->len);
    }
    else {
	fwrite(RSTRING(code)->ptr, 1, RSTRING(code)->len, out);
    }
    if (cgi) {
	fprintf(out, "</code></pre>\n");
	fprintf(out, "</td></tr>\n");
    }
    else {
	fprintf(out, "----------------------\n");
    }
}

char rfc822_days[][4] =
{
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};

char rfc822_months[][4] =
{
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

static char *rfc1123_time(time_t t)
{
    static char s[32];
    struct tm *tm;

    tm = gmtime(&t);
    sprintf(s, "%s, %.2d %s %d %.2d:%.2d:%.2d GMT",
	    rfc822_days[tm->tm_wday], tm->tm_mday, rfc822_months[tm->tm_mon],
	    tm->tm_year + 1900,	tm->tm_hour, tm->tm_min, tm->tm_sec);
    return s;
}

static void print_http_headers()
{
    char *tmp;

    if ((tmp = getenv("SERVER_PROTOCOL")) == NULL)
        tmp = "HTTP/1.0";
    printf("%s 200 OK\r\n", tmp);
    if ((tmp = getenv("SERVER_SOFTWARE")) == NULL)
	tmp = "unknown-server/0.0";
    printf("Server: %s\r\n", tmp);
    printf("Date: %s\r\n", rfc1123_time(time(NULL)));
    printf("Connection: close\r\n");
}

static void error_print(FILE *out, int state, int cgi, int mode, VALUE code)
{
    char buff[BUFSIZ];

#if RUBY_VERSION_CODE < 180
    rb_defout = rb_stdout;
#endif
    if (cgi) {
	char *imgdir;
	if ((imgdir = getenv("SCRIPT_NAME")) == NULL)
	    imgdir = "UNKNOWN_IMG_DIR";
        if (mode == MODE_NPHCGI)
            print_http_headers();
        fprintf(out, "Content-Type: text/html\r\n");
        fprintf(out, "Content-Style-Type: text/css\r\n");
        fprintf(out, "\r\n");
	fprintf(out, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\">\n");
	fprintf(out, "<html>\n");
	fprintf(out, "<head>\n");
	fprintf(out, "<title>eRuby</title>\n");
	fprintf(out, "<style type=\"text/css\">\n");
	fprintf(out, "<!--\n");
	fprintf(out, "body { background-color: #ffffff }\n");
	fprintf(out, "table { width: 100%%; padding: 5pt; border-style: none }\n");
	fprintf(out, "th { color: #6666ff; background-color: #b0d0d0; text-align: left }\n");
	fprintf(out, "td { color: #336666; background-color: #d0ffff }\n");
	fprintf(out, "strong { color: #ff0000; font-weight: bold }\n");
	fprintf(out, "div.backtrace { text-indent: 15%% }\n");
	fprintf(out, "#version { color: #ff9900 }\n");
	fprintf(out, "-->\n");
	fprintf(out, "</style>\n");
	fprintf(out, "</head>\n");
	fprintf(out, "<body>\n");
        fprintf(out, "<table summary=\"eRuby error information\">\n");
        fprintf(out, "<caption>\n");
	fprintf(out, "<img src=\"%s/logo.png\" alt=\"eRuby\">\n", imgdir);
        fprintf(out, "<span id=version>version: %s</span>\n", ERUBY_VERSION);
        fprintf(out, "</caption>\n");
        fprintf(out, "<tr><th id=\"error\">\n");
        fprintf(out, "ERROR\n");
        fprintf(out, "</th></tr>\n");
        fprintf(out, "<tr><td headers=\"error\">\n");
    }

    switch (state) {
    case TAG_RETURN:
	error_pos(out, cgi);
	fprintf(out, ": unexpected return\n");
	break;
    case TAG_NEXT:
	error_pos(out, cgi);
	fprintf(out, ": unexpected next\n");
	break;
    case TAG_BREAK:
	error_pos(out, cgi);
	fprintf(out, ": unexpected break\n");
	break;
    case TAG_REDO:
	error_pos(out, cgi);
	fprintf(out, ": unexpected redo\n");
	break;
    case TAG_RETRY:
	error_pos(out, cgi);
	fprintf(out, ": retry outside of rescue clause\n");
	break;
    case TAG_RAISE:
    case TAG_FATAL:
	exception_print(out, cgi);
	break;
    default:
	error_pos(out, cgi);
	snprintf(buff, BUFSIZ, ": unknown longjmp status %d", state);
	fputs(buff, out);
	break;
    }
    if (cgi) {
        fprintf(out, "</td></tr>\n");
    }

    if (!NIL_P(code))
	print_generated_code(out, code, cgi);

    if (cgi) {
        fprintf(out, "</table>\n");
	fprintf(out, "</body>\n");
	fprintf(out, "</html>\n");
    }
}

static VALUE defout_write(VALUE self, VALUE str)
{
    str = rb_obj_as_string(str);
    rb_str_cat(self, RSTRING(str)->ptr, RSTRING(str)->len);
    return Qnil;
}

static VALUE defout_cancel(VALUE self)
{
    if (RSTRING(self)->len == 0) return Qnil;
    RSTRING(self)->len = 0;
    RSTRING(self)->ptr[0] = '\0';
    return Qnil;
}

static int guess_mode()
{
    if (getenv("GATEWAY_INTERFACE") == NULL) {
	return MODE_FILTER;
    }
    else {
	char *name = getenv("SCRIPT_FILENAME");
        int result;
        char *buff;

        if (name == NULL) return MODE_CGI;

        buff = eruby_xmalloc(strlen(name) + 1);
        strcpy(buff, name);
        if ((name = strrchr(buff, '/')) != NULL) 
            *name++ = '\0';
        else 
            name = buff;
        if (strncasecmp(name, "nph-", 4) == 0) 
            result = MODE_NPHCGI;
        else
            result = MODE_CGI;
        free(buff);
        return result;
    }
}

static void give_img_logo(int mode)
{
    if (mode == MODE_NPHCGI)
	print_http_headers();
    printf("Content-Type: image/png\r\n\r\n");
    fwrite(eruby_logo_data, eruby_logo_size, 1, stdout);
}

static void init()
{
    ruby_init();
#if RUBY_VERSION_CODE >= 160
    ruby_init_loadpath();
#else
#if RUBY_VERSION_CODE >= 145
    rb_ary_push(rb_load_path, rb_str_new2("."));
#endif
#endif
    if (eruby_mode == MODE_CGI || eruby_mode == MODE_NPHCGI)
	rb_set_safe_level(1);

#if RUBY_VERSION_CODE >= 180
    rb_io_binmode(rb_stdout);	/* for mswin32 */
    rb_stdout = rb_str_new("", 0);
    rb_define_singleton_method(rb_stdout, "write", defout_write, 1);
    rb_define_singleton_method(rb_stdout, "cancel", defout_cancel, 0);
#else
    rb_defout = rb_str_new("", 0);
    rb_io_binmode(rb_stdout);	/* for mswin32 */
    rb_define_singleton_method(rb_defout, "write", defout_write, 1);
    rb_define_singleton_method(rb_defout, "cancel", defout_cancel, 0);
#endif
    eruby_init();
}

static void eruby_exit(status)
{
    ruby_finalize();
    exit(status);
}

static void proc_args(int argc, char **argv)
{
    int option_index;

    ruby_script(argv[0]);

    switch (eruby_parse_options(argc, argv, &option_index)) {
    case 1:
	eruby_exit(0);
    case 2:
	eruby_exit(2);
    }

    if (eruby_mode == MODE_UNKNOWN)
	eruby_mode = guess_mode();

    if (eruby_mode == MODE_CGI || eruby_mode == MODE_NPHCGI) {
	char *path;
        char *tmp_qs;
	char *query_string;
	int qs_has_equal;
	char *path_translated;

	if ((path = getenv("PATH_INFO")) != NULL &&
	    strcmp(path, "/logo.png") == 0) {
	    give_img_logo(eruby_mode);
	    eruby_exit(0);
	}

	if ((tmp_qs = getenv("QUERY_STRING")) == NULL) {
	    query_string = "";
        }
        else {
            query_string = eruby_xmalloc(strlen(tmp_qs) + 1);
            strcpy(query_string, tmp_qs);
        }
	qs_has_equal = (strchr(query_string, '=') != NULL);

	if ((path_translated = getenv("PATH_TRANSLATED")) == NULL)
	    path_translated = "";

	if (path_translated[0] &&
	    ((option_index == argc &&
	      (!query_string[0] || qs_has_equal)) ||
	     (option_index == argc - 1 &&
	      !qs_has_equal && strcmp(argv[option_index], query_string) == 0))) {
	    eruby_filename = path_translated;
	}
	else if ((option_index == argc - 1 &&
		  (!query_string[0] || qs_has_equal)) ||
		 (option_index == argc - 2 &&
		  !qs_has_equal &&
		  strcmp(argv[option_index + 1], query_string) == 0)) {
	    eruby_filename = argv[option_index];
	}
	else {
	    fprintf(stderr, "%s: missing required file to process\n", argv[0]);
	    eruby_exit(1);
	}
        if (tmp_qs) free(query_string);
    }
    else {
	if (option_index == argc) {
	    eruby_filename = "-";
	}
	else {
	    eruby_filename = argv[option_index++];
            ruby_set_argv(argc - option_index, argv + option_index);
	}
    }
}

static void run()
{
    VALUE stack_start;
    VALUE code;
    int state;
    char *out;
    int nout;
    void Init_stack _((VALUE*));

    Init_stack(&stack_start);
    code = eruby_load(eruby_filename, 0, &state);
    if (state && !rb_obj_is_kind_of(ruby_errinfo, rb_eSystemExit)) {
	if (RTEST(ruby_debug) &&
	    (eruby_mode == MODE_CGI || eruby_mode == MODE_NPHCGI)) {
	    error_print(stdout, state, 1, eruby_mode, code);
	    eruby_exit(0);
	}
	else {
	    error_print(stderr, state, 0, eruby_mode, code);
	    eruby_exit(1);
	}
    }
    if (eruby_mode == MODE_FILTER && (RTEST(ruby_debug) || RTEST(ruby_verbose))) {
	print_generated_code(stderr, code, 0);
    }
    rb_exec_end_proc();
#if RUBY_VERSION_CODE >= 180
    out = RSTRING(rb_stdout)->ptr;
    nout = RSTRING(rb_stdout)->len;
#else
    out = RSTRING(rb_defout)->ptr;
    nout = RSTRING(rb_defout)->len;
#endif
    if (!eruby_noheader &&
	(eruby_mode == MODE_CGI || eruby_mode == MODE_NPHCGI)) {
	if (eruby_mode == MODE_NPHCGI)
	    print_http_headers();

	printf("Content-Type: text/html; charset=%s\r\n", ERUBY_CHARSET);
	printf("Content-Length: %d\r\n", nout);
	printf("\r\n");
    }
    fwrite(out, nout, 1, stdout);
    fflush(stdout);
    ruby_finalize();
}

int main(int argc, char **argv)
{
    init();
    proc_args(argc, argv);
    run();
    return 0;
}

/*
 * Local variables:
 * mode: C
 * tab-width: 8
 * End:
 */
