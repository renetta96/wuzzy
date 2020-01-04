import os
import argparse
import shutil
import re

base_dir = os.path.dirname(os.path.realpath(__file__))
build_dir = os.path.join(base_dir, 'build')

os.makedirs(build_dir, exist_ok=True)

def get_modinfo_version():
	with open(os.path.join(base_dir, 'modinfo.lua'), 'r') as modinfo:
		content = modinfo.read()
		m = re.search(r'version.*=.*\"(.+)\"', content)
		return m.group(1)

version = get_modinfo_version()
print("VERSION = {}".format(version))

mod_build_dir = os.path.join(build_dir, "Ozzy Hamlet {}".format(version))
shutil.rmtree(mod_build_dir, ignore_errors=True)
os.makedirs(mod_build_dir, exist_ok=True)

for d in ('anim', 'scripts', 'bigportraits', 'images', 'sound'):
	shutil.copytree(os.path.join(base_dir, d), os.path.join(mod_build_dir, d))

for f in ('modicon.tex', 'modicon.xml', 'modinfo.lua', 'modmain.lua', 'modpic.png'):
	shutil.copy2(os.path.join(base_dir, f), os.path.join(mod_build_dir, f))

def rm_files_without_exts(path, exts):
	for item in os.listdir(path):
		item_path = os.path.join(path, item)

		if os.path.isdir(item_path):
			rm_files_without_exts(item_path, exts)
		else:
			filename, file_ext = os.path.splitext(item_path)

			if file_ext not in exts:
				os.remove(item_path)

rm_files_without_exts(os.path.join(mod_build_dir, 'sound'), ['.fev', '.fsb'])
rm_files_without_exts(os.path.join(mod_build_dir, 'images'), ['.tex', '.xml'])
rm_files_without_exts(os.path.join(mod_build_dir, 'bigportraits'), ['.tex', '.xml'])
