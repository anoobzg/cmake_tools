#include <openvdb/openvdb.h>
#include <openvdb/util/Util.h>
#include <iostream>

int main()
{
    openvdb::initialize();
    openvdb::FloatGrid::Ptr grid = openvdb::FloatGrid::create();
    openvdb::FloatGrid::Accessor accessor = grid->getAccessor();
    openvdb::Coord xyz(1000, -200000000, 30000000);
    accessor.setValue(xyz, 1.0);
    std::cout << "Grid" << xyz << " = " << accessor.getValue(xyz) << std::endl;

    const auto& offsets = openvdb::v11_0::util::COORD_OFFSETS;
}
