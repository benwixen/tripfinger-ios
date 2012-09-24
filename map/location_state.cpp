#include "location_state.hpp"
#include "navigator.hpp"
#include "framework.hpp"
#include "compass_filter.hpp"
#include "rotate_screen_task.hpp"

#include "../yg/display_list.hpp"

#include "../anim/controller.hpp"

#include "../gui/controller.hpp"

#include "../platform/location.hpp"
#include "../platform/platform.hpp"

#include "../geometry/rect2d.hpp"
#include "../geometry/transformations.hpp"

#include "../indexer/mercator.hpp"

namespace location
{
  State::State(Params const & p)
    : base_t(p),
      m_compassFilter(this),
      m_hasPosition(false),
      m_hasCompass(false),
      m_isCentered(false),
      m_locationProcessMode(ELocationDoNothing),
      m_compassProcessMode(ECompassDoNothing)
  {
    m_locationAreaColor = p.m_locationAreaColor;
    m_locationBorderColor = p.m_locationBorderColor;
    m_compassAreaColor = p.m_compassAreaColor;
    m_compassBorderColor = p.m_compassBorderColor;
    m_framework = p.m_framework;
    m_boundRects.resize(1);
  }

  bool State::HasPosition() const
  {
    return m_hasPosition;
  }

  bool State::HasCompass() const
  {
    return m_hasCompass;
  }

  void State::TurnOff()
  {
    m_hasPosition = false;
    m_hasCompass = false;
    setIsVisible(false);
  }

  void State::SkipLocationCentering()
  {
    m_locationProcessMode = ELocationSkipCentering;
  }

  ELocationProcessMode State::LocationProcessMode() const
  {
    return m_locationProcessMode;
  }

  void State::SetLocationProcessMode(ELocationProcessMode mode)
  {
    m_locationProcessMode = mode;
  }

  ECompassProcessMode State::CompassProcessMode() const
  {
    return m_compassProcessMode;
  }

  void State::SetCompassProcessMode(ECompassProcessMode mode)
  {
    m_compassProcessMode = mode;
  }

  void State::OnLocationStatusChanged(location::TLocationStatus newStatus)
  {
    switch (newStatus)
    {
    case location::EStarted:

      if (m_locationProcessMode != ELocationSkipCentering)
        m_locationProcessMode = ELocationCenterAndScale;
      break;

    case location::EFirstEvent:

      if (m_locationProcessMode != ELocationSkipCentering)
      {
        // set centering mode for the first location
        m_locationProcessMode = ELocationCenterAndScale;
        m_compassProcessMode = ECompassFollow;
      }
      break;

    default:
      m_locationProcessMode = ELocationDoNothing;
      TurnOff();
    }

    m_framework->Invalidate();
  }

  void State::OnGpsUpdate(location::GpsInfo const & info)
  {
    double lon = info.m_longitude;
    double lat = info.m_latitude;

    m2::RectD rect = MercatorBounds::MetresToXY(lon, lat, info.m_horizontalAccuracy);
    m2::PointD const center = rect.Center();

    m_hasPosition = true;
    setIsVisible(true);
    m_position = center;
    m_errorRadius = rect.SizeX() / 2;

    switch (m_locationProcessMode)
    {
    case ELocationCenterAndScale:
    {
      int const rectScale = scales::GetScaleLevel(rect);
      int setScale = -1;

      // correct rect scale if country isn't downloaded
      int const upperScale = scales::GetUpperWorldScale();
      if (rectScale > upperScale && !m_framework->IsCountryLoaded(center))
        setScale = upperScale;
      else
      {
        // correct rect scale for best user experience
        int const bestScale = scales::GetUpperScale() - 1;
        if (rectScale > bestScale)
          setScale = bestScale;
      }

      if (setScale != -1)
        rect = scales::GetRectForLevel(setScale, center, 1.0);

      double a = m_framework->GetNavigator().Screen().GetAngle();
      double dx = rect.SizeX();
      double dy = rect.SizeY();

      m_framework->ShowRectFixed(m2::AnyRectD(rect.Center(), a, m2::RectD(-dx/2, -dy/2, dx/2, dy/2)));

      SetIsCentered(true);
      CheckFollowCompass();

      m_locationProcessMode = ELocationCenterOnly;
      break;
    }

    case ELocationCenterOnly:
      m_framework->SetViewportCenter(center);

      SetIsCentered(true);
      CheckFollowCompass();

      break;

    case ELocationSkipCentering:
      SetIsCentered(false);
      m_locationProcessMode = ELocationDoNothing;
      break;

    case ELocationDoNothing:
      break;
    }

    m_framework->Invalidate();
  }

  void State::OnCompassUpdate(location::CompassInfo const & info)
  {
    m_hasCompass = true;
    m_compassFilter.OnCompassUpdate(info);
    m_framework->Invalidate();
  }

  vector<m2::AnyRectD> const & State::boundRects() const
  {
    if (isDirtyRect())
    {
      m_boundRects[0] = m2::AnyRectD(m_boundRect);
      setIsDirtyRect(false);
    }

    return m_boundRects;
  }

/*
  void State::cache()
  {
    m_cacheRadius = 500 * visualScale();

    yg::gl::Screen * cacheScreen = m_controller->GetCacheScreen();

    m_locationDisplayList.reset();
    m_locationDisplayList.reset(cacheScreen->createDisplayList());

    m_compassDisplayList.reset();
    m_compassDisplayList.reset(cacheScreen->createDisplayList());

    cacheScreen->beginFrame();
    cacheScreen->setDisplayList(m_locationDisplayList.get());

    m2::PointD zero(0, 0);

    cacheScreen->drawSymbol(zero,
                            "current_position",
                            yg::EPosCenter,
                            depth());

    cacheScreen->fillSector(zero,
                            0, 2.0 * math::pi,
                            m_cacheRadius,
                            m_locationAreaColor,
                            depth() - 3);

    cacheScreen->drawArc(zero,
                         0, 2.0 * math::pi,
                         m_cacheRadius,
                         m_locationBorderColor,
                         depth() - 2);

    cacheScreen->setDisplayList(m_compassDisplayList.get());

    cacheScreen->drawSector(zero,
                           -m_headingHalfErrorRad,
                            m_headingHalfErrorRad,
                            m_cacheRadius,
                            m_compassAreaColor,
                            depth());

    cacheScreen->fillSector(zero,
                           -m_headingHalfErrorRad,
                            m_headingHalfErrorRad,
                            m_cacheRadius,
                            m_compassBorderColor,
                            depth() - 1);

    cacheScreen->setDisplayList(0);
    cacheScreen->endFrame();
  }

  void State::purge()
  {
    m_locationDisplayList.reset();
    m_compassDisplayList.reset();
  }

  void State::update()
  {
    m2::PointD const pxPosition = m_framework->GetNavigator().GtoP(Position());

    setPivot(pxPosition);

    double const pxErrorRadius = pxPosition.Length(m_framework->GetNavigator().GtoP(Position() + m2::PointD(m_errorRadius, 0.0)));

    m2::RectD newRect(pxPosition - m2::PointD(pxErrorRadius, pxErrorRadius),
                      pxPosition + m2::PointD(pxErrorRadius, pxErrorRadius));

    if (newRect != m_boundRect)
    {
      m_boundRect = newRect;
      setIsDirtyRect(true);
    }
  }

  void State::draw(yg::gl::OverlayRenderer * r,
                   math::Matrix<double, 3, 3> const & m) const
  {
    if (isVisible())
    {
      checkDirtyDrawing();

      if (m_hasPosition)
      {
        m2::PointD const pxPosition = m_framework->GetNavigator().GtoP(Position());
        double const pxErrorRadius = pxPosition.Length(m_framework->GetNavigator().GtoP(Position() + m2::PointD(m_errorRadius, 0.0)));
        double const orientationRadius = max(pxErrorRadius, 30.0 * visualScale());

        double screenAngle = m_framework->GetNavigator().Screen().GetAngle();

        double k = pxErrorRadius / m_cacheRadius;

        math::Matrix<double, 3, 3> locationDrawM =
            math::Shift(
              math::Scale(math::Identity<double, 3>(), k, k),
              pivot()
              );

        m_locationDisplayList->draw(locationDrawM * m);

        // 0 angle is for North ("up"), but in our coordinates it's to the right.
        double headingRad = m_headingRad - math::pi / 2.0;

        if (m_hasCompass)
        {
          k = orientationRadius / m_cacheRadius;

          math::Matrix<double, 3, 3> compassDrawM =
              math::Shift(
                math::Rotate(
                  math::Scale(math::Identity<double, 3>(), k, k),
                  screenAngle + headingRad),
                pivot());

          m_compassDisplayList->draw(compassDrawM * m);
        }
      }
    }
  }
*/

  void State::draw(yg::gl::OverlayRenderer * r,
                   math::Matrix<double, 3, 3> const & m) const
  {
    if (isVisible())
    {
      checkDirtyDrawing();

      if (m_hasPosition)
      {
        m2::PointD const pxPosition = m_framework->GetNavigator().GtoP(Position());
        double const pxErrorRadius = pxPosition.Length(
              m_framework->GetNavigator().GtoP(Position() + m2::PointD(m_errorRadius, 0.0)));

        double screenAngle = m_framework->GetNavigator().Screen().GetAngle();

        r->drawSymbol(pxPosition,
                     "current-position",
                      yg::EPosCenter,
                      depth());

        r->fillSector(pxPosition,
                      0, 2.0 * math::pi,
                      pxErrorRadius,
                      m_locationAreaColor,
                      depth() - 3);

        if (m_hasCompass)
        {
          double const orientationRadius = max(pxErrorRadius, 30.0 * visualScale());
          // 0 angle is for North ("up"), but in our coordinates it's to the right.
          double const headingRad = m_compassFilter.GetHeadingRad() - math::pi / 2.0;
          double const halfErrorRad = m_compassFilter.GetHeadingHalfErrorRad();

          r->drawSector(pxPosition,
                        screenAngle + headingRad - halfErrorRad,
                        screenAngle + headingRad + halfErrorRad,
                        orientationRadius,
                        m_compassAreaColor,
                        depth());

          r->fillSector(pxPosition,
                        screenAngle + headingRad - halfErrorRad,
                        screenAngle + headingRad + halfErrorRad,
                        orientationRadius,
                        m_compassBorderColor,
                        depth() - 1);
        }
      }
    }
  }

  bool State::hitTest(m2::PointD const & pt) const
  {
    return false;
  }

  void State::CheckFollowCompass()
  {
    if (m_hasCompass
    && (CompassProcessMode() == ECompassFollow)
    && IsCentered())
      FollowCompass();
  }

  void State::FollowCompass()
  {
    if (!m_framework->GetNavigator().DoSupportRotation())
      return;

    shared_ptr<anim::Controller> controller = m_framework->GetRenderPolicy()->GetAnimController();

    controller->Lock();

    double startAngle = m_framework->GetNavigator().Screen().GetAngle();
    double endAngle = -m_compassFilter.GetHeadingRad();

    m_framework->GetAnimator().RotateScreen(startAngle, endAngle, 2);

    controller->Unlock();
  }

  void State::StopCompassFollowing()
  {
    SetCompassProcessMode(ECompassDoNothing);
    m_framework->GetAnimator().StopRotation();
  }

  bool State::IsCentered() const
  {
    return m_isCentered;
  }

  void State::SetIsCentered(bool flag)
  {
    m_isCentered = flag;
  }
}
