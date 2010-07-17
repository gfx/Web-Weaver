#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef USE_PPPORT
#include "ppport.h"
#endif

XS(XS_Web__Weaver__proxy);
XS(XS_Web__Weaver__proxy) {
    dVAR; dXSARGS;


}

MODULE = Web::Weaver	PACKAGE = Web::Weaver

PROTOTYPES: DISABLE

CV*
_to_psgi(CV* request_rewriter)
CODE:
{
    RETVAL = newXS(NULL, XS_Web__Weaver__proxy, __FILE__);
    sv_2mortal((SV*)RETVAL);
}
OUTPUT:
    RETVAL
