package com.tripfinger.map.base;

import android.support.v4.app.Fragment;

public class BaseMwmFragment extends Fragment
{
  @Override
  public void onResume()
  {
    super.onResume();
//    org.alohalytics.Statistics.logEvent("$onResume", this.getClass().getSimpleName()
//        + ":" + UiUtils.deviceOrientationAsString(getActivity()));
  }

  @Override
  public void onPause()
  {
    super.onPause();
//    org.alohalytics.Statistics.logEvent("$onPause", this.getClass().getSimpleName());
  }

  public BaseMwmFragmentActivity getMwmActivity()
  {
    return (BaseMwmFragmentActivity) getActivity();
  }
}
