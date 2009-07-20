#include "StdAfx.h"
#include "WindowLister.h"
#include "WindowItem.h"

namespace winmgr { 
  using namespace System;
  using namespace System::Runtime::InteropServices;

  WindowLister::WindowLister(void) {
    this->windows = gcnew ArrayList();
  }

  ArrayList ^WindowLister::GetWindows() {
    EnumWindowsCallback ^ewc = \
      gcnew EnumWindowsCallback(this, &WindowLister::window_handler);
    pin_ptr<EnumWindowsCallback ^> pinner = &ewc;
    IntPtr ewc_ptr = Marshal::GetFunctionPointerForDelegate(ewc);
    WNDENUMPROC enumproc = static_cast<WNDENUMPROC>(ewc_ptr.ToPointer());
    EnumWindows(enumproc, 0);

    return this->windows;
  }

  /* winapi types because this is invoked by a winapi (EnumWIndows) call */
  BOOL WindowLister::window_handler(HWND hwnd, LPARAM lparam) {
    /* nothing right now */
    WindowItem ^wi = gcnew WindowItem();
	wchar_t data[200];
    wi->hwnd = hwnd;
    GetWindowText(hwnd, data, 200);
	wi->title = gcnew String(data);
    this->windows->Add(wi);
    return TRUE;
  }
}
