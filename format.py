import os
import subprocess

def run_format(lua_file):
    cmd = 'C:\\nvm4w\\nodejs\\luafmt.cmd -i 2 -l 120 -w replace ' + lua_file
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)

    assert result.returncode == 0, "failed to format " + lua_file

def find_lua_files():
    lua_files = [os.path.join(os.getcwd(), 'modmain.lua')]
    for root, _, files in os.walk(os.path.join(os.getcwd(), 'scripts')):
        for file in files:
            if file.endswith('.lua'):
                lua_files.append(os.path.join(root, file))


    return lua_files

lua_files = find_lua_files()
print('Total:', len(lua_files))
for lua_file in lua_files:
    run_format(lua_file)
    print("Formatted {}".format(lua_file))
