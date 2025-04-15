$remote = "stable"
$conanPackages = conan search *  
foreach ($package in $conanPackages -split "\n") {
    #conan upload $package --remote=$remote --all
    if($package.Contains("/"))
    {
        echo $package
        conan upload $package -r stable --all
    }
}