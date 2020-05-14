import click,re
from os import path
from urllib.parse import urlparse
from urllib.parse import urlunparse

@click.command()
@click.option('--base','base_',required=True,type=click.Path(exists=False),help='to be completed')
@click.argument('input', type=click.File('r'))
@click.argument('output', type=click.File('w'))
def css_remap(base_,input,output):
    #
    def do_remap(mo):
        p = mo.group(0)
        r = path.relpath(p,base_)
        return r
    #
    input_css = input.read()
    pattern = re.compile(r'(?<=url\(\").+?(?=\"\))')
    output_css = re.sub(pattern,do_remap,input_css)
    output.write(output_css)

@click.command()
@click.option('--scheme','scheme_',required=True,type=click.Choice(['http', 'https'], case_sensitive=True))
@click.option('--start','start_',required=True,type=click.Path(exists=False,allow_dash=False))
@click.option('--path','path_',required=True,type=click.Path(exists=False,allow_dash=False))
def url_absolute(scheme_,start_,path_):
    url = path.relpath(path_, start_) 
    url = "//" + url
    part = urlparse(url)  
    result = urlunparse(part._replace(scheme = scheme_))
    click.echo(click.format_filename(result))

@click.command()
def otro():
    click.echo('/* * this is a fake stylesheet * */')
    pass