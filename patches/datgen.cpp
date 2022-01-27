#include <fstream>
#include <string>
#include <cstring>
#include <vector>

int main(int a, char** argv)
{
    std::ifstream input_data(argv[1]);
    std::string str((std::istreambuf_iterator<char>(input_data)),
                    std::istreambuf_iterator<char>());
    std::vector<uint32_t> tmp(str.size()/sizeof(uint32_t) + (str.size()%sizeof(uint32_t)!=0));
    memcpy(&tmp[0], &str[0], str.size());
    for(auto t : tmp) printf("%08X\n",t);
}