"""helper"""
import re
from os import path
import click


@click.command()
@click.option('--base', 'base_', required=True, type=click.Path(exists=False), help='to be completed')
@click.argument('input', type=click.File('r'))
@click.argument('output', type=click.File('w'))
def css_remap(base_, input_, output):
    """css-remap
    rewrite css urls"""
    #
    def do_remap(mo):
        p = mo.group(0)
        r = path.relpath(p, base_)
        return r
    #
    input_css = input_.read()
    pattern = re.compile(r'(?<=url\(\").+?(?=\"\))')
    output_css = re.sub(pattern, do_remap, input_css)
    output.write(output_css)


@click.command()
def otro():
    """otro"""
    click.echo('/* * this is a fake stylesheet * */')
