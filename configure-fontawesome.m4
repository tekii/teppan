# Font Awesome MACROS
m4_divert_push([MAKEFILE])dnl
m4_text_box(FONTAWESOME DEPS BEGIN,[+])
ifndef __VENDOR_FA__
__VENDOR_FA__=1
__VENDOR__/fontawesome-free-5.13.0-web.zip : | $$(@D)/
	wget -P __VENDOR__ https://use.fontawesome.com/releases/v5.13.0/fontawesome-free-5.13.0-web.zip
__VENDOR__/fontawesome-free-5.13.0-web __VENDOR__/fontawesome-free-5.13.0-web/css/all.css : __VENDOR__/fontawesome-free-5.13.0-web.zip
	unzip -q -d __VENDOR__ __VENDOR__/fontawesome-free-5.13.0-web.zip
vendor: __VENDOR__/fontawesome-free-5.13.0-web
endif
dnl
dnl this file its supose to be included after the __PAGE MACRO
dnl was expanded in the page (the layout file is the place)
dnl
m4_set_foreach([__BUILD_TARGETS__],[__I__],[dnl
m4_unquote(m4_cdr(__I__)) : __VENDOR__/fontawesome-free-5.13.0-web/css/all.css
])dnl
m4_text_box(FONTAWESOME DEPS END  ,[-])
m4_divert_pop([MAKEFILE])dnl
dnl
m4_divert_push([CUSTOM_STYLES])dnl
__CSS_REMAP_URLS(m4_esyscmd_s([cat ]__VENDOR__/fontawesome-free-5.13.0-web/css/all.css),
                 __VENDOR__/fontawesome-free-5.13.0-web/css)[]dnl
m4_divert_pop([CUSTOM_STYLES])dnl
