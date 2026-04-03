#include "MathParser.h"
#include "PathUtil.h"
#include "StringUtil.h"

#include <cstdlib>
#include <iostream>
#include <string>

int main()
{
    std::wstring widened = StringUtil::WidenUTF8("\xd0\xa2\xc4\x94st");
    if (widened != L"\u0422\u0114st")
    {
        std::cerr << "StringUtil::WidenUTF8 failed" << std::endl;
        return 1;
    }

    std::string narrowed = StringUtil::NarrowUTF8(L"\u0422\u0114st");
    if (narrowed != "\xd0\xa2\xc4\x94st")
    {
        std::cerr << "StringUtil::NarrowUTF8 failed" << std::endl;
        return 1;
    }

    std::wstring envPath = L"%HOME%/rainmeter";
    PathUtil::ExpandEnvironmentVariables(envPath);
    if (envPath.find(L"%HOME%") != std::wstring::npos)
    {
        std::cerr << "PathUtil::ExpandEnvironmentVariables failed" << std::endl;
        return 1;
    }

    double result = 0.0;
    const WCHAR* error = MathParser::CheckedParse(L"(1+2)*3", &result);
    if (error != nullptr || result != 9.0)
    {
        std::cerr << "MathParser::CheckedParse failed" << std::endl;
        return 1;
    }

    std::cout << "Portable core smoke test passed." << std::endl;
    return 0;
}
