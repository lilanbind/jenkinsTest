using UnityEngine;
using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

#if UNITY_EDITOR
using UnityEditor;

public static class BuildManager
{
	static readonly string APP_BASE_NAME = "T7";
	static readonly string OUTPUT_DIR_NAME = "output";

	static readonly string OSX_APP_NAME = APP_BASE_NAME + ".app";
	static readonly string WIN_APP_NAME = APP_BASE_NAME + ".exe";

	// this is the abstract configuration:
	// DEBUG OR QC OR RELEASE
	// which represents the full configuration

	// CONFIG_DEBUG is a standard development configuration
	const string CONFIG_DEBUG = "CONFIG_DEBUG;ENABLE_USER_METRICS";
	// CONFIG_RELEASE is an optimised configuration
	const string CONFIG_RELEASE = "CONFIG_RELEASE;ENABLE_USER_METRICS";
	// CONFIG_DISTRIBUTION is a release configuration on a non-development branch, for distribution to customers
	const string CONFIG_DISTRIBUTION = ";CONFIG_DISTRIBUTION";

	// this is the concrete configuration symbols
	// defined for each abstract configuration
	const string COMMON_DEFINES = "ASSERTS";

	const string RELEASE_DEFINES = CONFIG_RELEASE + ";" + COMMON_DEFINES;
	const string DEBUG_DEFINES = CONFIG_DEBUG + ";" + COMMON_DEFINES + ";LOGS;WARNINGS;DEVELOPMENT;PROFILING";

	const string OSX_DEFINES = "";
	const string WIN_DEFINES = "";

	enum BuildConfiguration
	{
		INVALID = 0,
		DEBUG,
		RELEASE,
		END
	}

	static string OutputPath
	{
		get
		{
			string path = Path.Combine(Application.dataPath, "../..");
			// Unity Editor: <path to project folder>/Assets
			path = Path.Combine(path, OUTPUT_DIR_NAME);
			return Path.GetFullPath(path);
		}
	}


	static string GetOutputDirectory(string subDirectory)
	{
		return Path.Combine(OutputPath, APP_BASE_NAME + "_" + subDirectory);
	}


	static string EnsureOutputDirectoryExists(string subDirectory)
	{
		string path = GetOutputDirectory(subDirectory);

		if (!Directory.Exists(path))
		{
			Directory.CreateDirectory(path);
		}

		return path;
	}

	static void SwitchBuildTarget(BuildTarget target)
	{
		var targetGroup = BuildTargetGroup.Standalone;
		EditorUserBuildSettings.SwitchActiveBuildTarget(targetGroup, target);
		EditorUserBuildSettings.selectedBuildTargetGroup = targetGroup;
		EditorUserBuildSettings.selectedStandaloneTarget = target;
	}

	static void SwitchToMacOS()
	{
		SwitchBuildTarget(BuildTarget.StandaloneOSX);
		PlayerSettings.fullScreenMode = FullScreenMode.Windowed;
	}

	static void SwitchToWindows()
	{
		SwitchBuildTarget(BuildTarget.StandaloneWindows);
	}

	static void SwitchToDebug()
	{
		EditorUserBuildSettings.allowDebugging = true;
		EditorUserBuildSettings.connectProfiler = true;
		EditorUserBuildSettings.explicitNullChecks = true;
		EditorUserBuildSettings.development = true;
		PlayerSettings.usePlayerLog = true;
		SetCurrentDefinedSymbols(DEBUG_DEFINES);
	}

	static void SwitchToRelease()
	{
		EditorUserBuildSettings.allowDebugging = false;
		EditorUserBuildSettings.connectProfiler = false;
		EditorUserBuildSettings.explicitNullChecks = false;
		EditorUserBuildSettings.development = false;
		PlayerSettings.usePlayerLog = false;
		SetCurrentDefinedSymbols(RELEASE_DEFINES);
	}

	static string AppendPlatformSymbols(string symbols)
	{
		string platformSymbols = null;

		switch (EditorUserBuildSettings.selectedStandaloneTarget)
		{
		case BuildTarget.StandaloneOSX:
			platformSymbols = OSX_DEFINES; break;

		case BuildTarget.StandaloneWindows:
			platformSymbols = WIN_DEFINES; break;
		}

		if (!string.IsNullOrEmpty(platformSymbols))
		{
			symbols = symbols + ";" + platformSymbols;
		}

		return symbols;
	}

	static void SetCurrentDefinedSymbols(string symbols)
	{
		var actualSymbols = AppendPlatformSymbols(symbols);
		Debug.Log("BuildManager setting symbols: " + actualSymbols);
		PlayerSettings.SetScriptingDefineSymbolsForGroup(EditorUserBuildSettings.selectedBuildTargetGroup, actualSymbols);
	}

	static BuildConfiguration GetCurrentBuildConfiguration()
	{
		BuildConfiguration result = BuildConfiguration.INVALID;
		var defines = PlayerSettings.GetScriptingDefineSymbolsForGroup(EditorUserBuildSettings.selectedBuildTargetGroup);
		if (defines.Contains(CONFIG_RELEASE))
		{
			result = BuildConfiguration.RELEASE;
		}
		else if (defines.Contains(CONFIG_DEBUG))
		{
			result = BuildConfiguration.DEBUG;
		}
		else
		{
			Debug.LogError("Unknown build configuration! defines: " + defines);
		}
		return result;
	}

	[MenuItem("Take7/CI/Switch/Mac OS X Release")]
	static void SwitchToMacOSXRelease()
	{
		SwitchToMacOS();
		SwitchToRelease();
	}

	[MenuItem("Take7/CI/Switch/Mac OS X Debug")]
	static void SwitchToMacOSXDebug()
	{
		SwitchToMacOS();
		SwitchToDebug();
	}

	[MenuItem("Take7/CI/Switch/Windows Release")]
	static void SwitchToWindowsRelease()
	{
		SwitchToWindows();
		SwitchToRelease();
	}

	[MenuItem("Take7/CI/Switch/Windows Debug")]
	static void SwitchToWindowsDebug()
	{
		SwitchToWindows();
		SwitchToDebug();
	}

	static BuildOptions GetBuildOptions()
	{
		BuildOptions options = BuildOptions.None;
		var config = GetCurrentBuildConfiguration();
		Debug.Log("Build configuration: " + config);
		switch (config)
		{
		default: Debug.LogError("Invalid Configuration. Make sure you switch configuration using the CI menu"); break;
		case  BuildConfiguration.DEBUG: options |= BuildOptions.AllowDebugging | BuildOptions.ConnectWithProfiler | BuildOptions.Development; break;
		case  BuildConfiguration.RELEASE: break;
		}

		return options;
	}

	static void BuildWithCurrentSettings(string path)
	{
		string[] scenes = (from scene in EditorBuildSettings.scenes where scene.enabled select scene.path).ToArray();
		string error = null;
		var summary = BuildPipeline.BuildPlayer(scenes, path, EditorUserBuildSettings.selectedStandaloneTarget, GetBuildOptions()).summary;
		if (summary.result != UnityEditor.Build.Reporting.BuildResult.Succeeded)
		{
			error = summary.ToString();
		}

		if (!string.IsNullOrEmpty(error))
		{
			Debug.LogWarning("BuildPlayer Error: " + error);
		}
	}


	[MenuItem("Take7/CI/Build/Mac OS X Release")]
	static void BuildMacOSXRelease()
	{
		string path = EnsureOutputDirectoryExists("MacOSX_Release");
		path = Path.Combine(path, OSX_APP_NAME);
		Debug.LogWarning("BuildMacOSXRelease() @: " + path);
		SwitchToMacOSXRelease();
		BuildWithCurrentSettings(path);
	}

	[MenuItem("Take7/CI/Build/Mac OS X Debug")]
	static void BuildMacOSXDebug()
	{
		string path = EnsureOutputDirectoryExists("MacOSX_Debug");
		path = Path.Combine(path, OSX_APP_NAME);
		Debug.LogWarning("BuildMacOSXDebug() @: " + path);
		SwitchToMacOSXDebug();
		BuildWithCurrentSettings(path);
	}

	[MenuItem("Take7/CI/Build/Windows Release")]
	static void BuildWindowsRelease()
	{
		string path = EnsureOutputDirectoryExists("Windows_Release");
		path = Path.Combine(path, WIN_APP_NAME);
		Debug.LogWarning("BuildWindowsRelease() @: " + path);
		SwitchToWindowsRelease();
		BuildWithCurrentSettings(path);
	}

	[MenuItem("Take7/CI/Build/Windows Debug")]
	static void BuildWindowsDebug()
	{
		string path = EnsureOutputDirectoryExists("Windows_Debug");
		path = Path.Combine(path, WIN_APP_NAME);
		Debug.LogWarning("BuildWindowsDebug() @: " + path);
		SwitchToWindowsDebug();
		BuildWithCurrentSettings(path);
	}

	[MenuItem("Take7/Tools/Test Error output")]
	static void TestErrorOutput()
	{
		Debug.Assert(false, "FU!");
		Debug.LogError("BLA!");
		Debug.LogException(new System.Exception("BLU!"));
		throw new NullReferenceException("Null stuff");
	}
}

#endif