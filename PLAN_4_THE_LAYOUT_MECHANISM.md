# WITH_LAYOUT Problems

As the Claude code review reveals, the __LAYOUT__ definition mechanism needs to be reviewed and revisited, specially related to the WITH_LAYOUT macro duplication bug.

## Current situation / Problems / Bugs

- The file  `generator.m4` in the line 333 includes a layout file asumming the macro __LAYOUT__ was defined in the 
in the `configure.m4` and or modified after `m4_include(__FIRST__)` (arround line 329) by the WITH_LAYOUT macro itself, there is a duplication of the default layout definitions in the design one in the `configure.m4` and a second in the macro definition itself througt the `m4_default` (see `m4_include(__LAYOUT__)dnl`). The definition in the configure allows simple content files `*.in.html` whitout WITH_XXX macro invocation, but as the code review reveal create a duplication.

- The command line in the test direct invocation of the generator has a `-D __LAYOUT__ = XXX`.

- Since we assume only one layout per page generation there is no reason for the m4_pushdef / m4_popdef, any previous definition should be considered as a faltal errror an invoque `m4_fatal` abortin the generation.


## An initial approach

- Since we already have a default mechanism througt the `configure.m4` file, the optional parameter in the WITH_LAYOUT looks redundant, if we decide to use the macro is to change the layout, what i meant was that the parameter sholuld be mandatory, then if you use the macro you MUST provide the alternative layout else the use of the macro has no porpouse.

