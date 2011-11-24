#include "classificator_loader.hpp"
#include "classificator.hpp"
#include "drawing_rules.hpp"

#include "../../platform/platform.hpp"

#include "../coding/reader_streambuf.hpp"

#include "../base/logging.hpp"

#include "../std/fstream.hpp"


namespace classificator
{
  void ReadCommon(Reader * classificator,
                  Reader * visibility,
                  Reader * types)
  {
    Classificator & c = classif();
    c.Clear();

    {
      //LOG(LINFO, ("Reading classificator"));
      ReaderStreamBuf buffer(classificator);

      istream s(&buffer);
      c.ReadClassificator(s);
    }

    {
      //LOG(LINFO, ("Reading visibility"));
      ReaderStreamBuf buffer(visibility);

      istream s(&buffer);
      c.ReadVisibility(s);
    }

    {
      //LOG(LINFO, ("Reading types mapping"));
      ReaderStreamBuf buffer(types);

      istream s(&buffer);
      c.ReadTypesMapping(s);
    }
  }

  void ReadVisibility(string const & fPath)
  {
    ifstream s(fPath.c_str());
    classif().ReadVisibility(s);
  }

  void Load()
  {
    LOG(LINFO, ("Reading of classificator started"));

    Platform & p = GetPlatform();

    ReadCommon(p.GetReader("classificator.txt"),
               p.GetReader("visibility.txt"),
               p.GetReader("types.txt"));

    //LOG(LINFO, ("Reading of drawing rules"));
    drule::RulesHolder & rules = drule::rules();

    try
    {
      // Load from protobuffer binary file.
      ReaderStreamBuf buffer(p.GetReader("drules_proto.bin"));

      istream s(&buffer);
      rules.LoadFromBinaryProto(s);
    }
    catch (Reader::OpenException const &)
    {
      try
      {
        // Load from protobuffer text file.
        string buffer;
        ModelReaderPtr(p.GetReader("drules_proto.txt")).ReadAsString(buffer);

        rules.LoadFromTextProto(buffer);

        // Uncomment this to save actual drawing rules to binary proto format.
        //ofstream s(p.WritablePathForFile("drules_proto.bin").c_str(), ios::out | ios::binary);
        //rules.SaveToBinaryProto(buffer, s);
      }
      catch (Reader::OpenException const &)
      {
        LOG(LERROR, ("No drawing rules found"));
      }
    }

    LOG(LINFO, ("Reading of classificator finished"));
  }
}
