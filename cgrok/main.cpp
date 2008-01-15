
#include <iostream>
#include <fstream>
#include <string>
#include <boost/xpressive/xpressive.hpp>

using namespace std;
using namespace boost::xpressive;

#include "grokpatternset.hpp"
#include "grokregex.hpp"
#include "grokmatch.hpp"

int main(int argc, char **argv) {
  GrokPatternSet<sregex> default_set;
  ifstream pattern_file("./patterns");
  string pattern_desc;
  const string delim(" \t");

  while (getline(pattern_file, pattern_desc)) {
    string::size_type pos;
    string name;
    string regex_str;
    if (pattern_desc.size() == 0)
      continue;
    if (pattern_desc[0] == '#')
      continue;
    pos = pattern_desc.find_first_of(delim, 0);
    name = pattern_desc.substr(0, pos);
    pos = pattern_desc.find_first_not_of(delim, pos);
    regex_str = pattern_desc.substr(pos, pattern_desc.size() - pos);
    default_set.AddPattern(name, regex_str);
    //cout << name << " => " << regex_str << endl;
  }

  if (argc != 2) {
    cout << "Usage: $0 [regexp]" << endl;
    exit(1);
  }

  GrokMatch<sregex> *gm;
  GrokRegex<sregex> gre(argv[1]);
  gre.AddPatternSet(default_set);

  GrokMatch<sregex>::match_map_type m;

  string str;
  while (getline(cin, str)) {
    //cout << "Line: " << str << endl;
    gm = gre.Search(str);
    if (gm == NULL)
      continue;

    m = gm->GetMatches();
    GrokMatch<sregex>::match_map_type::const_iterator iter;
    for (iter = m.begin(); iter != m.end(); iter++) {
      string key, val;
      key = (*iter).first;
      val = (*iter).second;
      cout << key << " => " << val << endl;
    }

    delete gm;
  }

  return 0;
}
