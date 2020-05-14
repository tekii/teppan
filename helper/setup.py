from setuptools import setup
setup(
    name='helper',
    version='0.1',
    py_modules=['helper'],
    install_requires=[
        'Click',
    ],
    entry_points='''
        [console_scripts]
        helper-css-remap=helper:css_remap
        helper-url-absolute=helper:url_absolute
        helper-otro=helper:otro
    ''',
)