dnl
dnl DEFAULT LAYOUT, COULD BE REDEFINED IN PAGE MACRO
dnl
m4_define([__LAYOUT__],__SRC__/layout.html)
m4_define([__MICROSOFT_VALIDATE_KEY__],[62098880540BA63FB5E4BCEED0264D10])
m4_define([__TEKII__],[<strong>TEKii$1</strong>])
m4_define([__TEKII_SRL_]_,__TEKII__([ SRL]))
dnl
m4_divert_push([MAKEFILE])dnl 
m4_divert_pop([MAKEFILE])
dnl MACROS TO AVOID ERRORS IN CSS HIGHLIGHT BECOSE M4<>CSS SYNTAX
m4_define([__MAGIC_COMMENT_TO_AVOID_MESSING_WITH_CSS_HIGHLIGHT_WHILE_INCLUDE_AMP_CUSTOM_CSS__],[dnl
 BEGIN AMP-CUSTOM.CSS */m4_newline([])__INCL([amp-custom.css])m4_newline([/* END AMP-CUSTOM.CSS ])])
m4_define([__MAGIC_COMMENT_TO_AVOID_MESSING_WITH_CSS_HIGHLIGHT_WHILE_UNDIVERT_CUSTOM_STYLES__],[dnl
 BEGIN CUSTOM STYLES */m4_newline([])m4_undivert([CUSTOM_STYLES])m4_newline([/* END CUSTOM STYLES ])])
dnl
m4_define([__ESENBR],[m4_case(__LANG__,dnl
__ES__,m4_dquote(m4_default([$1],[TEXTO A COMPLETAR])),dnl
__EN__,m4_dquote(m4_default([$2],[TO BE COMPLETED])),dnl
__BR__,m4_dquote(m4_default([$3],[SER COMPLETADO])),dnl
[__LANG__ UNDEFINED])])
