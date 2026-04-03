/* Copyright (C) 2013 Rainmeter Project Developers
 *
 * This Source Code Form is subject to the terms of the GNU General Public
 * License; either version 2 of the License, or (at your option) any later
 * version. If a copy of the GPL was not distributed with this file, You can
 * obtain one at <https://www.gnu.org/licenses/gpl-2.0.html>. */

#ifdef _WIN32
#include "StdAfx.h"
#else
#include <algorithm>
#include <cctype>
#include <codecvt>
#include <cstdio>
#include <cstring>
#include <cwchar>
#include <locale>
#endif
#include "StringUtil.h"

namespace {

// Is the character a end of sentence punctuation character?
// English only?
bool IsEOSPunct(wchar_t ch)
{
	return ch == '?' || ch == '!' || ch == '.';
}

}

namespace StringUtil {

std::string Narrow(const WCHAR* str, int strLen, int cp)
{
	std::string narrowStr;

	if (str && *str)
	{
		if (strLen == -1)
		{
			strLen = (int)wcslen(str);
		}

	#ifdef _WIN32
		int bufLen = WideCharToMultiByte(cp, 0, str, strLen, nullptr, 0, nullptr, nullptr);
		if (bufLen > 0)
		{
			narrowStr.resize(bufLen);
			WideCharToMultiByte(cp, 0, str, strLen, &narrowStr[0], bufLen, nullptr, nullptr);
		}
	#else
		std::wstring input(str, strLen);
		if (cp == CP_UTF8)
		{
			std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
			narrowStr = converter.to_bytes(input);
		}
		else
		{
			std::mbstate_t state{};
			const wchar_t* src = input.c_str();
			size_t len = std::wcsrtombs(nullptr, &src, 0, &state);
			if (len != static_cast<size_t>(-1))
			{
				narrowStr.resize(len);
				state = std::mbstate_t{};
				src = input.c_str();
				std::wcsrtombs(&narrowStr[0], &src, narrowStr.size(), &state);
			}
		}
	#endif
	}
	return narrowStr;
}

std::wstring Widen(const char* str, int strLen, int cp)
{
	std::wstring wideStr;

	if (str && *str)
	{
		if (strLen == -1)
		{
			strLen = (int)strlen(str);
		}

	#ifdef _WIN32
		int bufLen = MultiByteToWideChar(cp, 0, str, strLen, nullptr, 0);
		if (bufLen > 0)
		{
			wideStr.resize(bufLen);
			MultiByteToWideChar(cp, 0, str, strLen, &wideStr[0], bufLen);
		}
	#else
		std::string input(str, strLen);
		if (cp == CP_UTF8)
		{
			std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
			wideStr = converter.from_bytes(input);
		}
		else
		{
			std::mbstate_t state{};
			const char* src = input.c_str();
			size_t len = std::mbsrtowcs(nullptr, &src, 0, &state);
			if (len != static_cast<size_t>(-1))
			{
				wideStr.resize(len);
				state = std::mbstate_t{};
				src = input.c_str();
				std::mbsrtowcs(&wideStr[0], &src, wideStr.size(), &state);
			}
		}
	#endif
	}
	return wideStr;
}

void LTrim(std::wstring& str)
{
	str.erase(str.begin(), std::find_if(str.begin(), str.end(),
		[](wint_t ch) { return !std::iswspace(ch); }));
}

void RTrim(std::wstring& str)
{
	str.erase(std::find_if(str.rbegin(), str.rend(),
		[](wint_t ch) { return !std::iswspace(ch); }).base(), str.end());
}

void Trim(std::wstring& str)
{
	LTrim(str);
	RTrim(str);
}

size_t StripLeadingAndTrailingQuotes(std::wstring& str, bool single)
{
	if (str.size() > 1ULL)
	{
		WCHAR first = str.front();
		WCHAR last = str.back();
		if ((first == L'"' && last == L'"') ||				// "some string"
			(single && first == L'\'' && last == L'\''))	// 'some string'
		{
			str.erase(0ULL, 1ULL);
			str.erase(str.size() - 1ULL);
		}
	}
	return str.size();
}

void ToLowerCase(std::wstring& str)
{
	if (str.empty()) return;

#ifdef _WIN32
	WCHAR* srcAndDest = &str[0];
	int strAndDestLen = (int)str.length();
	LCMapString(LOCALE_USER_DEFAULT, LCMAP_LOWERCASE, srcAndDest, strAndDestLen, srcAndDest, strAndDestLen);
#else
	std::transform(str.begin(), str.end(), str.begin(), [](wchar_t ch) { return std::towlower(ch); });
#endif
}

void ToUpperCase(std::wstring& str)
{
	if (str.empty()) return;

#ifdef _WIN32
	WCHAR* srcAndDest = &str[0];
	int strAndDestLen = (int)str.length();
	LCMapString(LOCALE_USER_DEFAULT, LCMAP_UPPERCASE, srcAndDest, strAndDestLen, srcAndDest, strAndDestLen);
#else
	std::transform(str.begin(), str.end(), str.begin(), [](wchar_t ch) { return std::towupper(ch); });
#endif
}

void ToProperCase(std::wstring& str)
{
	if (str.empty()) return;

#ifdef _WIN32
	WCHAR* srcAndDest = &str[0];
	int strAndDestLen = (int)str.length();
	LCMapString(LOCALE_USER_DEFAULT, LCMAP_TITLECASE, srcAndDest, strAndDestLen, srcAndDest, strAndDestLen);
#else
	bool uppercaseNext = true;
	for (wchar_t& ch : str)
	{
		if (std::iswspace(ch))
		{
			uppercaseNext = true;
		}
		else if (uppercaseNext)
		{
			ch = std::towupper(ch);
			uppercaseNext = false;
		}
		else
		{
			ch = std::towlower(ch);
		}
	}
#endif
}

void ToSentenceCase(std::wstring& str)
{
	if (!str.empty())
	{
		ToLowerCase(str);
		bool isCapped = false;

		for (size_t i = 0; i < str.length(); ++i)
		{
			if (IsEOSPunct(str[i])) isCapped = false;

			if (!isCapped && iswalpha(str[i]) != 0)
			{
			#ifdef _WIN32
				WCHAR* srcAndDest = &str[i];
				LCMapString(LOCALE_USER_DEFAULT, LCMAP_UPPERCASE, srcAndDest, 1, srcAndDest, 1);
			#else
				str[i] = std::towupper(str[i]);
			#endif
				isCapped = true;
			}
		}
	}
}

/*
** Escapes reserved PCRE regex metacharacters.
*/
void EscapeRegExp(std::wstring& str)
{
	size_t start = 0;
	while ((start = str.find_first_of(L"\\^$|()[{.+*?", start)) != std::wstring::npos)
	{
		str.insert(start, L"\\");
		start += 2;
	}
}

/*
** Escapes reserved URL characters.
*/
void EncodeUrl(std::wstring& str, bool doReserved)
{
	static const std::string unreserved = "0123456789-.ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcedefghijklmnopqrstuvwxyz~";
	std::string utf8 = NarrowUTF8(str);
	for (size_t pos = 0; pos < utf8.size(); ++pos)
	{
		unsigned char ch = static_cast<unsigned char>(utf8[pos]);
		if ((ch <= 0x20 || ch >= 0x7F) ||                              // control characters and non-ascii (includes space)
			(doReserved && unreserved.find(ch) == std::string::npos))  // any character other than unreserved characters
		{
			char buffer[3];
			std::snprintf(buffer, sizeof(buffer), "%.2X", ch);
			utf8[pos] = '%';
			utf8.insert(pos + 1, buffer);
			pos += 2;
		}
	}
	str = WidenUTF8(utf8);
}

/*
** Case insensitive comparison of strings. If equal, strip str2 from str1 and any leading whitespace.
*/
bool CaseInsensitiveCompareN(std::wstring& str1, const std::wstring& str2)
{
	size_t pos = str2.length();
	bool equal = str1.length() >= pos;
	for (size_t i = 0; equal && i < pos; ++i)
	{
		equal = std::towlower(str1[i]) == std::towlower(str2[i]);
	}

	if (equal)
	{
		str1 = str1.substr(pos);  // remove str2 from str1
		str1.erase(0, str1.find_first_not_of(L" \t\r\n"));  // remove any leading whitespace
		return true;
	}

	return false;
}

}  // namespace StringUtil
