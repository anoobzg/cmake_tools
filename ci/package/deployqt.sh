find $1/Contents/PlugIns -name "*.dylib" | while read plugin; do
    base_path="${plugin#$1/Contents/PlugIns/}"
    echo "install_name_tool change id plugin: $plugin"
    install_name_tool -id "@executable_path/../PlugIns/${base_path}" "$plugin" &> /dev/null
done

find $1/Contents/PlugIns -name "*.dylib" | while read plugin; do
  otool -L "$plugin" | grep "/opt/homebrew" | awk '{print $1}' | while read dep; do
    base_dep=${dep#*/lib/}
    echo "install_name_tool change dep plugin: $dep"
    install_name_tool -change "$dep" \
      "@executable_path/../Frameworks/$base_dep" \
      "$plugin" &> /dev/null
  done
done