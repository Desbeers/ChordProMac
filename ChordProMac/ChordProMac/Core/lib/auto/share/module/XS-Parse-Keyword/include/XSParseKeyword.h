#ifndef __XS_PARSE_KEYWORD_H__
#define __XS_PARSE_KEYWORD_H__

#define XSPARSEKEYWORD_ABI_VERSION 2

struct XSParseKeywordPieceType;
struct XSParseKeywordPieceType {
  int type;
  union {
    char c;                                       /* LITERALCHAR */
    const char *str;                              /* LITERALSTR */
    const struct XSParseKeywordPieceType *pieces; /* containers */
    void (*callback)(pTHX_ void *hookdata);       /* SETUP, ANONSUB PREPARE+START */

    OP *(*op_wrap_callback)(pTHX_ OP *o, void *hookdata);
  } u;
};

enum {
  XPK_FLAG_EXPR       = (1<<0),
  XPK_FLAG_STMT       = (1<<1),
  XPK_FLAG_AUTOSEMI   = (1<<2),
  XPK_FLAG_BLOCKSCOPE = (1<<3),
};

enum {
  /* skip zero */

  /*                                    emits */
  XS_PARSE_KEYWORD_LITERALCHAR = 1,   /* nothing */
  XS_PARSE_KEYWORD_LITERALSTR,        /* nothing */
  XS_PARSE_KEYWORD_AUTOSEMI,          /* nothing */
  XS_PARSE_KEYWORD_WARNING = 0x0e,    /* nothing */
  XS_PARSE_KEYWORD_FAILURE,           /* nothing */

  XS_PARSE_KEYWORD_BLOCK = 0x10,      /* op */
  XS_PARSE_KEYWORD_ANONSUB,           /* cv */
  XS_PARSE_KEYWORD_ARITHEXPR,         /* op */
  XS_PARSE_KEYWORD_TERMEXPR,          /* op */
  XS_PARSE_KEYWORD_LISTEXPR,          /* op */
  /* TODO: XS_PARSE_KEYWORD_FULLEXPR = 0x15 */
  XS_PARSE_KEYWORD_IDENT = 0x16,      /* sv */
  XS_PARSE_KEYWORD_PACKAGENAME,       /* sv */
  XS_PARSE_KEYWORD_LEXVARNAME,        /* sv */
  XS_PARSE_KEYWORD_LEXVAR,            /* padix */
  XS_PARSE_KEYWORD_ATTRS,             /* i / {attr.name + attr.val} */
  XS_PARSE_KEYWORD_VSTRING,           /* sv */

  XS_PARSE_KEYWORD_INFIX = 0x40,      /* infix */

  XS_PARSE_KEYWORD_INTRO_MY = 0x60,   /* emits nothing */

  XS_PARSE_KEYWORD_SETUP = 0x70,      /* invokes callback, emits nothing */

  XS_PARSE_KEYWORD_ANONSUB_PREPARE,   /* invokes callback, emits nothing */
  XS_PARSE_KEYWORD_ANONSUB_START,     /* invokes callback, emits nothing */
  XS_PARSE_KEYWORD_ANONSUB_END,       /* invokes op_wrap_callback, emits nothing */
  XS_PARSE_KEYWORD_ANONSUB_WRAP,      /* invokes op_wrap_callback, emits nothing */

  XS_PARSE_KEYWORD_SEQUENCE = 0x80,   /* contained */
  XS_PARSE_KEYWORD_REPEATED,          /* i, contained */
  XS_PARSE_KEYWORD_CHOICE,            /* i, contained */
  XS_PARSE_KEYWORD_TAGGEDCHOICE,      /* i, contained */
  XS_PARSE_KEYWORD_SEPARATEDLIST,     /* i, contained */
  XS_PARSE_KEYWORD_PARENS = 0xb0,     /* contained */
  XS_PARSE_KEYWORD_BRACKETS,          /* contained */
  XS_PARSE_KEYWORD_BRACES,            /* contained */
  XS_PARSE_KEYWORD_CHEVRONS,          /* contained */
};

enum {
  XPK_LEXVAR_SCALAR = (1<<0),
  XPK_LEXVAR_ARRAY  = (1<<1),
  XPK_LEXVAR_HASH   = (1<<2),
  XPK_LEXVAR_ANY    = XPK_LEXVAR_SCALAR|XPK_LEXVAR_ARRAY|XPK_LEXVAR_HASH,
};

enum {
  XPK_TYPEFLAG_OPT      = (1<<16),
  XPK_TYPEFLAG_SPECIAL  = (1<<17), /* on XPK_LITERALSTR: keyword
                                      on XPK_BLOCK: scoped
                                      on XPK_LEXVAR: my */

  /* These three are shifted versions of perl's G_VOID, G_SCALAR, G_LIST */
  XPK_TYPEFLAG_G_VOID   = (1<<18),
  XPK_TYPEFLAG_G_SCALAR = (2<<18),
  XPK_TYPEFLAG_G_LIST   = (3<<18),

  XPK_TYPEFLAG_ENTERLEAVE = (1<<20), /* wrap ENTER/LEAVE pair around the item */

  XPK_TYPEFLAG_MAYBEPARENS = (1<<21), /* parens themselves are optional on PARENS */
};

#define XPK_PREFIXED(typecode,...) \
  {.type = typecode, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }}

#define XPK_BLOCK_flags(flags) {.type = XS_PARSE_KEYWORD_BLOCK|(flags), .u.pieces = NULL}
#define XPK_BLOCK              XPK_BLOCK_flags(0)
#define XPK_BLOCK_VOIDCTX      XPK_BLOCK_flags(XPK_TYPEFLAG_SPECIAL|XPK_TYPEFLAG_G_VOID)
#define XPK_BLOCK_SCALARCTX    XPK_BLOCK_flags(XPK_TYPEFLAG_SPECIAL|XPK_TYPEFLAG_G_SCALAR)
#define XPK_BLOCK_LISTCTX      XPK_BLOCK_flags(XPK_TYPEFLAG_SPECIAL|XPK_TYPEFLAG_G_LIST)

#define XPK_PREFIXED_BLOCK(...)            XPK_PREFIXED(XS_PARSE_KEYWORD_BLOCK, __VA_ARGS__)
#define XPK_PREFIXED_BLOCK_ENTERLEAVE(...) XPK_PREFIXED(XS_PARSE_KEYWORD_BLOCK|XPK_TYPEFLAG_ENTERLEAVE, __VA_ARGS__)

#define XPK_SETUP(setup)       {.type = XS_PARSE_KEYWORD_SETUP, .u.callback = setup}

#define XPK_ANONSUB {.type = XS_PARSE_KEYWORD_ANONSUB}

#define XPK_ANONSUB_PREPARE(func)  {.type = XS_PARSE_KEYWORD_ANONSUB_PREPARE, .u.callback = func}
#define XPK_ANONSUB_START(func)    {.type = XS_PARSE_KEYWORD_ANONSUB_START, .u.callback = func}
#define XPK_ANONSUB_END(func)      {.type = XS_PARSE_KEYWORD_ANONSUB_END, .u.op_wrap_callback = func}
#define XPK_ANONSUB_WRAP(func)     {.type = XS_PARSE_KEYWORD_ANONSUB_WRAP, .u.op_wrap_callback = func}

#define XPK_STAGED_ANONSUB(...) \
  {.type = XS_PARSE_KEYWORD_ANONSUB, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }}

#define XPK_ARITHEXPR_flags(flags)  {.type = XS_PARSE_KEYWORD_ARITHEXPR|(flags)}
#define XPK_ARITHEXPR               XPK_ARITHEXPR_flags(0)
#define XPK_ARITHEXPR_VOIDCTX       XPK_ARITHEXPR_flags(XPK_TYPEFLAG_G_VOID)
#define XPK_ARITHEXPR_SCALARCTX     XPK_ARITHEXPR_flags(XPK_TYPEFLAG_G_SCALAR)
#define XPK_ARITHEXPR_OPT           XPK_ARITHEXPR_flags(XPK_TYPEFLAG_OPT)
#define XPK_ARITHEXPR_VOIDCTX_OPT   XPK_ARITHEXPR_flags(XPK_TYPEFLAG_G_VOID|XPK_TYPEFLAG_OPT)
#define XPK_ARITHEXPR_SCALARCTX_OPT XPK_ARITHEXPR_flags(XPK_TYPEFLAG_G_SCALAR|XPK_TYPEFLAG_OPT)

#define XPK_TERMEXPR_flags(flags)  {.type = XS_PARSE_KEYWORD_TERMEXPR|(flags)}
#define XPK_TERMEXPR               XPK_TERMEXPR_flags(0)
#define XPK_TERMEXPR_VOIDCTX       XPK_TERMEXPR_flags(XPK_TYPEFLAG_G_VOID)
#define XPK_TERMEXPR_SCALARCTX     XPK_TERMEXPR_flags(XPK_TYPEFLAG_G_SCALAR)
#define XPK_TERMEXPR_OPT           XPK_TERMEXPR_flags(XPK_TYPEFLAG_OPT)
#define XPK_TERMEXPR_VOIDCTX_OPT   XPK_TERMEXPR_flags(XPK_TYPEFLAG_G_VOID|XPK_TYPEFLAG_OPT)
#define XPK_TERMEXPR_SCALARCTX_OPT XPK_TERMEXPR_flags(XPK_TYPEFLAG_G_SCALAR|XPK_TYPEFLAG_OPT)

#define XPK_PREFIXED_TERMEXPR_ENTERLEAVE(...) XPK_PREFIXED(XS_PARSE_KEYWORD_TERMEXPR|XPK_TYPEFLAG_ENTERLEAVE, __VA_ARGS__)

#define XPK_LISTEXPR_flags(flags) {.type = XS_PARSE_KEYWORD_LISTEXPR|(flags)}
#define XPK_LISTEXPR              XPK_LISTEXPR_flags(0)
#define XPK_LISTEXPR_LISTCTX      XPK_LISTEXPR_flags(XPK_TYPEFLAG_G_LIST)
#define XPK_LISTEXPR_OPT          XPK_LISTEXPR_flags(XPK_TYPEFLAG_OPT)
#define XPK_LISTEXPR_LISTCTX_OPT  XPK_LISTEXPR_flags(XPK_TYPEFLAG_G_LIST|XPK_TYPEFLAG_OPT)

#define XPK_PREFIXED_LISTEXPR_ENTERLEAVE(...) XPK_PREFIXED(XS_PARSE_KEYWORD_LISTEXPR|XPK_TYPEFLAG_ENTERLEAVE, __VA_ARGS__)

#define XPK_IDENT           {.type = XS_PARSE_KEYWORD_IDENT                       }
#define XPK_IDENT_OPT       {.type = XS_PARSE_KEYWORD_IDENT      |XPK_TYPEFLAG_OPT}
#define XPK_PACKAGENAME     {.type = XS_PARSE_KEYWORD_PACKAGENAME                 }
#define XPK_PACKAGENAME_OPT {.type = XS_PARSE_KEYWORD_PACKAGENAME|XPK_TYPEFLAG_OPT}

#define XPK_LEXVARNAME(kind) {.type = XS_PARSE_KEYWORD_LEXVARNAME, .u.c = kind}

#define XPK_LEXVAR(kind)    {.type = XS_PARSE_KEYWORD_LEXVAR, .u.c = kind}
#define XPK_LEXVAR_MY(kind) {.type = XS_PARSE_KEYWORD_LEXVAR|XPK_TYPEFLAG_SPECIAL, .u.c = kind}

#define XPK_ATTRIBUTES {.type = XS_PARSE_KEYWORD_ATTRS}

#define XPK_VSTRING     {.type = XS_PARSE_KEYWORD_VSTRING}
#define XPK_VSTRING_OPT {.type = XS_PARSE_KEYWORD_VSTRING|XPK_TYPEFLAG_OPT}

#define XPK_COMMA  {.type = XS_PARSE_KEYWORD_LITERALCHAR, .u.c = ','}
#define XPK_COLON  {.type = XS_PARSE_KEYWORD_LITERALCHAR, .u.c = ':'}
#define XPK_EQUALS {.type = XS_PARSE_KEYWORD_LITERALCHAR, .u.c = '='}

#define XPK_LITERAL(s) {.type = XS_PARSE_KEYWORD_LITERALSTR, .u.str = (const char *)s}
#define XPK_STRING(s)  XPK_LITERAL(s)
#define XPK_AUTOSEMI   {.type = XS_PARSE_KEYWORD_AUTOSEMI}
#define XPK_KEYWORD(s) {.type = XS_PARSE_KEYWORD_LITERALSTR|XPK_TYPEFLAG_SPECIAL, .u.str = (const char *)s}

#define XPK_INFIX(select) {.type = XS_PARSE_KEYWORD_INFIX, .u.c = select}
#define XPK_INFIX_RELATION       XPK_INFIX(XPI_SELECT_RELATION)
#define XPK_INFIX_EQUALITY       XPK_INFIX(XPI_SELECT_EQUALITY)
#define XPK_INFIX_MATCH_NOSMART  XPK_INFIX(XPI_SELECT_MATCH_NOSMART)
#define XPK_INFIX_MATCH_SMART    XPK_INFIX(XPI_SELECT_MATCH_SMART)

#define XPK_INTRO_MY           {.type = XS_PARSE_KEYWORD_INTRO_MY}

#define XPK_SEQUENCE_pieces(p) {.type = XS_PARSE_KEYWORD_SEQUENCE, .u.pieces = p}
#define XPK_SEQUENCE(...)      XPK_SEQUENCE_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))

/* First piece of these must be something probe-able */
#define XPK_OPTIONAL_pieces(p) {.type = XS_PARSE_KEYWORD_SEQUENCE|XPK_TYPEFLAG_OPT, .u.pieces = p}
#define XPK_OPTIONAL(...)      XPK_OPTIONAL_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))

#define XPK_REPEATED_pieces(p) {.type = XS_PARSE_KEYWORD_REPEATED, .u.pieces = p}
#define XPK_REPEATED(...)      XPK_REPEATED_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))

/* Every piece must be probeable */
#define XPK_CHOICE_pieces(p)  {.type = XS_PARSE_KEYWORD_CHOICE, .u.pieces = p}
#define XPK_CHOICE(...)       XPK_CHOICE_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))

/* Every piece must be probeable, and followed by XPK_TAG */
#define XPK_TAGGEDCHOICE_pieces(p) {.type = XS_PARSE_KEYWORD_TAGGEDCHOICE, .u.pieces = p}
#define XPK_TAGGEDCHOICE(...)      XPK_TAGGEDCHOICE_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0}, {0} }))
#define XPK_TAG(val) {.type = val}

#define XPK_COMMALIST(...) \
  {.type = XS_PARSE_KEYWORD_SEPARATEDLIST, .u.pieces = (const struct XSParseKeywordPieceType []){ \
      {.type = XS_PARSE_KEYWORD_LITERALCHAR, .u.c = ','}, __VA_ARGS__, {0}}}

#define XPK_WARNING_bit(bit,s)   {.type = (XS_PARSE_KEYWORD_WARNING|(bit << 24)), .u.str = (const char *)s}
#define XPK_WARNING(s)               XPK_WARNING_bit(0,s)
#define XPK_WARNING_AMBIGUOUS(s)     XPK_WARNING_bit(WARN_AMBIGUOUS,   s)
#define XPK_WARNING_DEPRECATED(s)    XPK_WARNING_bit(WARN_DEPRECATED,  s)
#define XPK_WARNING_EXPERIMENTAL(s)  XPK_WARNING_bit(WARN_EXPERIMENTAL,s)
#define XPK_WARNING_PRECEDENCE(s)    XPK_WARNING_bit(WARN_PRECEDENCE,  s)
#define XPK_WARNING_SYNTAX(s)        XPK_WARNING_bit(WARN_SYNTAX,      s)

#define XPK_FAILURE(s) {.type = XS_PARSE_KEYWORD_FAILURE, .u.str = (const char *)s}

#define XPK_PARENS_pieces(p) {.type = XS_PARSE_KEYWORD_PARENS, .u.pieces = p}
#define XPK_PARENS(...)      XPK_PARENS_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))
#define XPK_PARENS_OPT(...) \
  {.type = XS_PARSE_KEYWORD_PARENS|XPK_TYPEFLAG_OPT, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }}

#define XPK_ARGS_pieces(p) {.type = XS_PARSE_KEYWORD_PARENS|XPK_TYPEFLAG_MAYBEPARENS, .u.pieces = p}
#define XPK_ARGS(...)      XPK_ARGS_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))

#define XPK_BRACKETS_pieces(p) {.type = XS_PARSE_KEYWORD_BRACKETS, .u.pieces = p}
#define XPK_BRACKETS(...)      XPK_BRACKETS_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))
#define XPK_BRACKETS_OPT(...) \
  {.type = XS_PARSE_KEYWORD_BRACKETS|XPK_TYPEFLAG_OPT, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }}

#define XPK_BRACES_pieces(p) {.type = XS_PARSE_KEYWORD_BRACES, .u.pieces = p}
#define XPK_BRACES(...)      XPK_BRACES_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))
#define XPK_BRACES_OPT(...) \
  {.type = XS_PARSE_KEYWORD_BRACES|XPK_TYPEFLAG_OPT, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }}

#define XPK_CHEVRONS_pieces(p) {.type = XS_PARSE_KEYWORD_CHEVRONS, .u.pieces = p}
#define XPK_CHEVRONS(...)      XPK_CHEVRONS_pieces(((const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }))
#define XPK_CHEVRONS_OPT(...) \
  {.type = XS_PARSE_KEYWORD_CHEVRONS|XPK_TYPEFLAG_OPT, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, {0} }}

/* back-compat for older names */
#define XPK_PARENSCOPE_pieces    XPK_PARENS_pieces
#define XPK_PARENSCOPE           XPK_PARENS
#define XPK_PARENSCOPE_OPT       XPK_PARENS_OPT
#define XPK_ARGSCOPE_pieces      XPK_ARGS_pieces
#define XPK_ARGSCOPE             XPK_ARGS
#define XPK_BRACKETSCOPE_pieces  XPK_BRACKETS_pieces
#define XPK_BRACKETSCOPE         XPK_BRACKETS
#define XPK_BRACKETSCOPE_OPT     XPK_BRACKETS_OPT
#define XPK_BRACESCOPE_pieces    XPK_BRACES_pieces
#define XPK_BRACESCOPE           XPK_BRACES
#define XPK_BRACESCOPE_OPT       XPK_BRACES_OPT
#define XPK_CHEVRONSCOPE_pieces  XPK_CHEVRONS_pieces
#define XPK_CHEVRONSCOPE         XPK_CHEVRONS
#define XPK_CHEVRONSCOPE_OPT     XPK_CHEVRONS_OPT

/* This type defined in XSParseInfix.h */
typedef struct XSParseInfixInfo XSParseInfixInfo;

typedef struct {
  union {
    OP *op;
    CV *cv;
    SV *sv;
    int i;
    struct { SV *name; SV *value; } attr;
    PADOFFSET padix;
    XSParseInfixInfo *infix;
  };
  int line;
} XSParseKeywordPiece;

struct XSParseKeywordHooks {
  U32 flags;

  /* used by build1 */
  struct XSParseKeywordPieceType piece1;
  /* alternatively, used by build */
  const struct XSParseKeywordPieceType *pieces;

  /* These two hooks are ANDed together; both must pass, if present */
  const char *permit_hintkey;
  bool (*permit) (pTHX_ void *hookdata);

  void (*check)(pTHX_ void *hookdata);

  /* These are alternatives; the first one defined is used */
  int (*parse)(pTHX_ OP **opp, void *hookdata);
  int (*build)(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata);
  int (*build1)(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata);
};

static void (*register_xs_parse_keyword_func)(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata);
#define register_xs_parse_keyword(kwname, hooks, hookdata)  S_register_xs_parse_keyword(aTHX_ kwname, hooks, hookdata)
static void S_register_xs_parse_keyword(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata)
{
  if(!register_xs_parse_keyword_func)
    croak("Must call boot_xs_parse_keyword() first");

  (*register_xs_parse_keyword_func)(aTHX_ kwname, hooks, hookdata);
}

#define boot_xs_parse_keyword(ver) S_boot_xs_parse_keyword(aTHX_ ver)
static void S_boot_xs_parse_keyword(pTHX_ double ver) {
  SV **svp;
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Keyword"), versv, NULL);

  svp = hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION_MIN", 0);
  if(!svp)
    croak("XS::Parse::Keyword ABI minimum version missing");
  int abi_ver = SvIV(*svp);
  if(abi_ver > XSPARSEKEYWORD_ABI_VERSION)
    croak("XS::Parse::Keyword ABI version mismatch - library supports >= %d, compiled for %d",
        abi_ver, XSPARSEKEYWORD_ABI_VERSION);

  svp = hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION_MAX", 0);
  abi_ver = SvIV(*svp);
  if(abi_ver < XSPARSEKEYWORD_ABI_VERSION)
    croak("XS::Parse::Keyword ABI version mismatch - library supports <= %d, compiled for %d",
        abi_ver, XSPARSEKEYWORD_ABI_VERSION);

  register_xs_parse_keyword_func = INT2PTR(void (*)(pTHX_ const char *, const struct XSParseKeywordHooks *, void *),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/register()@2", 0)));
}

#endif
