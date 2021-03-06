#pragma once

#include "indexer/mwm_set.hpp"

#include "std/cstdint.hpp"
#include "std/string.hpp"
#include "std/utility.hpp"
#include "search/v2/search_model.hpp"

namespace feature
{
enum EGeomType
{
  GEOM_UNDEFINED = -1,
  // Note! do not change this values. Should be equal with FeatureGeoType.
  GEOM_POINT = 0,
  GEOM_LINE = 1,
  GEOM_AREA = 2
};
}  // namespace feature

string DebugPrint(feature::EGeomType type);

class TripfingerMark
{
public:
  m2::PointD mercator;
  string name;

  int category;
  uint32_t type;
  string tripfingerId;

  string phone;
  string address;
  string website;
  string email;

  string content;
  string price;
  string openingHours;
  string directions;

  string url;
  string imageDescription;
  string license;
  string artist;
  string originalUrl;

  search::v2::SearchModel::SearchType searchType;
  bool offline = false;
  bool liked = false;
};

struct TripfingerMarkParams
{
  bool cancelled = false;
  m2::PointD topLeft;
  m2::PointD botRight;
  int zoomLevel;
  int category = 0;
  function<void (vector<TripfingerMark>)> callback;
};

struct FeatureID
{
  static char const * const kInvalidFileName;
  static int64_t const kInvalidMwmVersion;

  MwmSet::MwmId m_mwmId;
  uint32_t m_index;
  shared_ptr<TripfingerMark> tripfingerMark = nullptr;

  FeatureID() : m_index(0) {}
  FeatureID(MwmSet::MwmId const & mwmId, uint32_t index) : m_mwmId(mwmId), m_index(index) {}
  FeatureID(TripfingerMark const & mark) : m_mwmId(MwmSet::MwmId()), m_index(0) {
    tripfingerMark = make_shared<TripfingerMark>(mark);
  }

  bool IsValid() const {
    if (m_mwmId.IsAlive()) {
      return true;
    } else {
      return IsTripfinger();
    }
  }

  bool IsTripfinger() const {
    return tripfingerMark != nullptr;
  }

  inline bool operator<(FeatureID const & r) const
  {
    if (IsTripfinger() && r.IsTripfinger()) {
      return tripfingerMark->tripfingerId < r.tripfingerMark->tripfingerId;
    } else if (IsTripfinger()) {
      return false;
    } else if (r.IsTripfinger()) {
      return true;
    }
    if (m_mwmId == r.m_mwmId)
      return m_index < r.m_index;
    else
      return m_mwmId < r.m_mwmId;
  }

  inline bool operator==(FeatureID const & r) const
  {
    if (IsTripfinger() && r.IsTripfinger()) {
      return tripfingerMark->tripfingerId == r.tripfingerMark->tripfingerId;
    } else {
      return (m_mwmId == r.m_mwmId && m_index == r.m_index);
    }
  }

  inline bool operator!=(FeatureID const & r) const { return !(*this == r); }

  string GetMwmName() const;
  int64_t GetMwmVersion() const;

  friend string DebugPrint(FeatureID const & id);
};
