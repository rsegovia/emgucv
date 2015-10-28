REM @echo off
pushd %~p0
cd ..\..
IF "%1%"=="64" ECHO "BUILDING 64bit solution" 
IF NOT "%1%"=="64" ECHO "BUILDING 32bit solution"

SET NETFX_CORE=""
IF "%3%"=="WindowsPhoneDevice" SET NETFX_CORE="TRUE" 
IF "%3%"=="WindowsPhoneEmulator" SET NETFX_CORE="TRUE"
IF "%3%"=="WindowsStore" SET NETFX_CORE="TRUE"

SET OS_MODE=
IF "%1%"=="64" SET OS_MODE= Win64
IF "%3%"=="WindowsPhoneDevice" SET OS_MODE= ARM
REM IF "%3%"=="WindowsPhoneEmulator" SET OS_MODE= 32
SET PROGRAMFILES_DIR_X86=%programfiles(x86)%
if NOT EXIST "%PROGRAMFILES_DIR_X86%" SET PROGRAMFILES_DIR_X86=%programfiles%
SET PROGRAMFILES_DIR=%programfiles%

REM Find CMake  
SET CMAKE="cmake.exe"
IF EXIST "%PROGRAMFILES_DIR_X86%\CMake 2.8\bin\cmake.exe" SET CMAKE="%PROGRAMFILES_DIR_X86%\CMake 2.8\bin\cmake.exe"
IF EXIST "%PROGRAMFILES_DIR_X86%\CMake\bin\cmake.exe" SET CMAKE="%PROGRAMFILES_DIR_X86%\CMake\bin\cmake.exe"

IF EXIST "CMakeCache.txt" del CMakeCache.txt

REM Find Visual Studio or Msbuild
SET VS2005="%VS80COMNTOOLS%..\IDE\devenv.com"
SET VS2008="%VS90COMNTOOLS%..\IDE\devenv.com"
SET VS2010="%VS100COMNTOOLS%..\IDE\devenv.com"
SET VS2012="%VS110COMNTOOLS%..\IDE\devenv.com"
SET VS2013="%VS120COMNTOOLS%..\IDE\devenv.com"
SET MSBUILD35="%windir%\Microsoft.NET\Framework\v3.5\MSBuild.exe"

IF EXIST %MSBUILD35% SET DEVENV=%MSBUILD35%
IF EXIST %VS2005% SET DEVENV=%VS2005% 
IF EXIST %VS2008% SET DEVENV=%VS2008%
IF EXIST %VS2010% SET DEVENV=%VS2010%
IF "%4%"=="openni" GOTO SET_BUILD_TYPE
IF EXIST %VS2012%  SET DEVENV=%VS2012%
REM IF "%2%"=="gpu" GOTO SET_BUILD_TYPE
IF EXIST %VS2013%  SET DEVENV=%VS2013%

:SET_BUILD_TYPE
IF %DEVENV%==%MSBUILD35% SET BUILD_TYPE=/property:Configuration=Release
IF %DEVENV%==%VS2005% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2008% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2010% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2012% SET BUILD_TYPE=/Build Release
IF %DEVENV%==%VS2013% SET BUILD_TYPE=/Build Release

IF %DEVENV%==%MSBUILD35% SET CMAKE_CONF="Visual Studio 8 2005%OS_MODE%"
IF %DEVENV%==%VS2005% SET CMAKE_CONF="Visual Studio 8 2005%OS_MODE%"
IF %DEVENV%==%VS2008% SET CMAKE_CONF="Visual Studio 9 2008%OS_MODE%"
IF %DEVENV%==%VS2010% SET CMAKE_CONF="Visual Studio 10%OS_MODE%"
IF %DEVENV%==%VS2012% SET CMAKE_CONF="Visual Studio 11%OS_MODE%"
IF %DEVENV%==%VS2013% SET CMAKE_CONF="Visual Studio 12%OS_MODE%"

SET IPP_BUILD_FLAGS=-DWITH_IPP:BOOL=FALSE 

REM Setup common flags
SET CMAKE_CONF_FLAGS= -G %CMAKE_CONF% ^
-DBUILD_DOCS:BOOL=FALSE ^
-DBUILD_TESTS:BOOL=FALSE ^
-DBUILD_opencv_apps:BOOL=FALSE ^
-DBUILD_opencv_adas:BOOL=FALSE ^
-DBUILD_opencv_bioinspired:BOOL=FALSE ^
-DBUILD_opencv_python2:BOOL=FALSE ^
-DEMGU_ENABLE_SSE:BOOL=TRUE ^
-DCMAKE_INSTALL_PREFIX="%TEMP%" ^
-DBUILD_WITH_DEBUG_INFO:BOOL=FALSE ^
-DBUILD_WITH_STATIC_CRT:BOOL=FALSE ^
-DCMAKE_CONFIGURATION_TYPES=Release ^
-DWITH_OPENGL:BOOL=OFF ^
-DOPENCV_EXTRA_MODULES_PATH=opencv_contrib/modules 

IF NOT "%NETFX_CORE%"=="" (
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DBUILD_opencv_ts:BOOL=OFF ^
-DBUILD_PERF_TESTS:BOOL=OFF 
) ELSE (
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DBUILD_opencv_ts:BOOL=ON ^
-DBUILD_PERF_TESTS:BOOL=ON 
)

IF NOT "%4%"=="openni" GOTO END_OF_OPENNI

:WITH_OPENNI
SET OPENNI_LIB_DIR=%OPEN_NI_LIB%
IF "%OS_MODE%"==" Win64" SET OPENNI_LIB_DIR=%OPEN_NI_LIB64%
SET OPENNI_PS_BIN_DIR=%OPENNI_LIB_DIR%\..\..\PrimeSense\Sensor\Bin
IF "%OS_MODE%"==" Win64" SET OPENNI_PS_BIN_DIR=%OPENNI_LIB_DIR%\..\..\PrimeSense\Sensor\Bin64

IF EXIST "%OPENNI_LIB_DIR%" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DWITH_OPENNI:BOOL=TRUE ^
-DOPENNI_INCLUDE_DIR="%OPEN_NI_INCLUDE:\=/%" ^
-DOPENNI_LIB_DIR="%OPENNI_LIB_DIR:\=/%" ^
-DOPENNI_PRIME_SENSOR_MODULE_BIN_DIR="%OPENNI_PS_BIN_DIR:\=/%"
:END_OF_OPENNI


IF "%5%"=="doc" ^
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DEMGU_CV_DOCUMENTATION_BUILD:BOOL=TRUE 


IF NOT "%2%"=="gpu" GOTO WITHOUT_GPU
REM IF %DEVENV%==%VS2012% GOTO END_OF_GPU
REM IF %DEVENV%==%VS2013% GOTO END_OF_GPU

:WITH_GPU
REM Find cuda. Use Cuda 7 for 64 bit and Cuda 6.5 for 32bit
REM We cannot use cuda 7 for 32 bit because the 32bit version of npp has been depreciated from Cuda 7
IF "%OS_MODE%"==" Win64" (
SET CUDA_SDK_DIR=%CUDA_PATH%
) ELSE (
SET CUDA_SDK_DIR=%CUDA_PATH_V6_5%
)

IF %DEVENV%==%VS2008% SET CUDA_HOST_COMPILER=%VS90COMNTOOLS%..\..\VC\bin\cl.exe
IF %DEVENV%==%VS2010% SET CUDA_HOST_COMPILER=%VS100COMNTOOLS%..\..\VC\bin\cl.exe
IF %DEVENV%==%VS2012% SET CUDA_HOST_COMPILER=%VS110COMNTOOLS%..\..\VC\bin\cl.exe
IF %DEVENV%==%VS2013% SET CUDA_HOST_COMPILER=%VS120COMNTOOLS%..\..\VC\bin\cl.exe
REM SET CUDA_HOST_COMPILER=%DEVENV%

IF "%OS_MODE%"==" Win64" (
SET CUDA_64_MODE=-DCUDA_64_BIT_DEVICE_CODE:BOOL=TRUE
) ELSE (
SET CUDA_64_MODE=-DCUDA_64_BIT_DEVICE_CODE:BOOL=FALSE
)
IF EXIST "%CUDA_SDK_DIR%" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
%CUDA_64_MODE% ^
-DWITH_CUDA:BOOL=TRUE ^
-DCUDA_VERBOSE_BUILD:BOOL=TRUE ^
-DCUDA_TOOLKIT_ROOT_DIR="%CUDA_SDK_DIR:\=/%" ^
-DCUDA_SDK_ROOT_DIR="%CUDA_SDK_DIR:\=/%" ^
-DWITH_CUBLAS:BOOL=TRUE ^
-DCUDA_HOST_COMPILER="%CUDA_HOST_COMPILER%" ^
-DBUILD_SHARED_LIBS:BOOL=TRUE 

IF NOT "%8%"=="" (
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCUDA_ARCH_BIN:STRING="%7%" 
) ELSE (
IF EXIST "%CUDA_SDK_DIR%" SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCUDA_ARCH_BIN:STRING="2.0 2.1(2.0) 3.0 3.5 5.0 5.2"
)

GOTO END_OF_GPU

:WITHOUT_GPU
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DWITH_CUDA:BOOL=FALSE ^
-DBUILD_SHARED_LIBS:BOOL=FALSE 

:END_OF_GPU

SET BUILD_PROJECT=
IF "%6%"=="package" SET BUILD_PROJECT= /project PACKAGE 

IF "%3%"=="intel" GOTO INTEL_COMPILER

REM SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DWITH_IPP:BOOL=FALSE
GOTO VISUAL_STUDIO

:INTEL_COMPILER
REM Find Intel Compiler 
SET INTEL_DIR=%ICPP_COMPILER16%bin
SET INTEL_ENV=%INTEL_DIR%\iclvars.bat
SET INTEL_ICL=%INTEL_DIR%\ia32\icl.exe
IF "%OS_MODE%"==" Win64" SET INTEL_ICL=%INTEL_DIR%\intel64\icl.exe
SET INTEL_TBB=%ICPP_COMPILER15%tbb\include
REM IF "%OS_MODE%"==" Win64" SET INTEL_IPP=%ICPP_COMPILER15%redist\intel64\ipp
REM SET ICPROJCONVERT=%PROGRAMFILES_DIR_X86%\Common Files\Intel\shared files\ia32\Bin\ICProjConvert121.exe

REM initiate the compiler enviroment
@echo on

IF EXIST "%INTEL_DIR%" SET IPP_BUILD_FLAGS=-DWITH_IPP:BOOL=TRUE
IF EXIST "%INTEL_DIR%" SET CMAKE_CONF_FLAGS=^
-DWITH_TBB:BOOL=TRUE ^
-DTBB_INCLUDE_DIR="%INTEL_TBB:\=/%" ^
-DENABLE_PRECOMPILED_HEADERS:BOOL=FALSE ^
-DCV_ICC:BOOL=TRUE ^
%CMAKE_CONF_FLAGS%

IF NOT "%2%"=="gpu" GOTO END_OF_INTEL_GPU

REM SET CUDA_HOST_COMPILER=%VS110COMNTOOLS%..\..\VC\bin
REM IF "%OS_MODE%"==" Win64" SET CUDA_HOST_COMPILER=%CUDA_HOST_COMPILER%\amd64
REM IF EXIST %VS2012% SET CMAKE_CONF_FLAGS=^
REM -DCUDA_HOST_COMPILER="%CUDA_HOST_COMPILER%" ^
REM %CMAKE_CONF_FLAGS%
REM IF "%OS_MODE%"==" Win64" SET CMAKE_CONF_FLAGS=^
REM -DCUDA_64_BIT_DEVICE_CODE:BOOL=ON ^
REM %CMAKE_CONF_FLAGS%

:END_OF_INTEL_GPU

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% %IPP_BUILD_FLAGS% -DWITH_OPENCL:BOOL=TRUE 

REM create visual studio project
%CMAKE% %CMAKE_CONF_FLAGS%

GOTO BUILD

:VISUAL_STUDIO


SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% %IPP_BUILD_FLAGS% 
 
IF "%3%"=="WindowsStore" GOTO CONFIGURE_WINDOWS_STORE
IF "%3%"=="WindowsPhoneDevice" GOTO CONFIGURE_WINDOWS_PHONE
IF "%3%"=="WindowsPhoneEmulator" GOTO CONFIGURE_WINDOWS_PHONE

SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DWITH_OPENCL:BOOL=TRUE 
GOTO RUN_CMAKE

:CONFIGURE_WINDOWS_STORE
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCMAKE_SYSTEM_NAME="WindowsStore" -DCMAKE_SYSTEM_VERSION="8.1"
GOTO CONFIGURE_WINDOWS_STORE_OR_PHONE

:CONFIGURE_WINDOWS_PHONE
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% -DCMAKE_SYSTEM_NAME="WindowsPhone"  -DCMAKE_SYSTEM_VERSION="8.1" 
GOTO CONFIGURE_WINDOWS_STORE_OR_PHONE

:CONFIGURE_WINDOWS_STORE_OR_PHONE
SET CMAKE_CONF_FLAGS=%CMAKE_CONF_FLAGS% ^
-DBUILD_opencv_videostab:BOOL=OFF ^
-DBUILD_opencv_text:BOOL=ON ^
-DBUILD_opencv_dnn:BOOL=OFF ^
-DBUILD_opencv_saliency:BOOL=OFF ^
-DEMGU_CV_WITH_CVBLOB:BOOL=OFF ^
-DNETFX_CORE:BOOL=TRUE ^
-DWITH_DIRECTX:BOOL=FALSE ^
-DWITH_OPENEXR:BOOL=FALSE ^
-DWITH_TIFF:BOOL=TRUE ^
-DEMGU_CV_WITH_TIFF:BOOL=FALSE ^
-DWITH_PNG:BOOL=TRUE ^
-DWITH_WEBP:BOOL=TRUE ^
-DWITH_DSHOW:BOOL=FALSE ^
-DWITH_WIN32UI:BOOL=FALSE ^
-DWITH_VFW:BOOL=FALSE ^
-DWITH_MSMF:BOOL=FALSE ^
-DWITH_FFMPEG:BOOL=FALSE ^
-DWITH_OPENCL:BOOL=FALSE ^
-DEMGU_ENABLE_SSE:BOOL=FALSE 
GOTO RUN_CMAKE

@echo on
:RUN_CMAKE
%CMAKE% %CMAKE_CONF_FLAGS%

:BUILD
IF "%7%"=="build" ^
call %DEVENV% %BUILD_TYPE% emgucv.sln %BUILD_PROJECT% 

:END
popd