#!/usr/bin/env python3
"""Generate the checked-in Xcode project without third-party dependencies."""

from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "AI-Monitor.xcodeproj"


def oid(value: str) -> str:
    return hashlib.sha1(value.encode()).hexdigest().upper()[:24]


def quote(value: str) -> str:
    if value.replace("_", "").replace("-", "").replace(".", "").isalnum() and not value[0].isdigit():
        return value
    return '"' + value.replace('"', '\\"') + '"'


def swift_files(*roots: str) -> list[str]:
    values: list[str] = []
    for root in roots:
        values.extend(str(path.relative_to(ROOT)) for path in sorted((ROOT / root).rglob("*.swift")))
    return values


app_sources = swift_files("App", "Core", "Providers", "UI", "Shared")
widget_sources = swift_files("Widget") + [
    "Core/Models/UsageModels.swift",
    "Core/Formatting/UsageFormatters.swift",
    "Shared/SharedSnapshot.swift",
    "Shared/SharedSnapshotStore.swift",
]
test_sources = swift_files("Core", "Providers", "Shared", "Tests")
ui_test_sources = swift_files("UITests")

app_resources = [
    str(path.relative_to(ROOT))
    for path in sorted((ROOT / "Resources").iterdir())
    if path.name != "Fixtures"
]
test_resources = [
    str(path.relative_to(ROOT)) for path in sorted((ROOT / "Resources" / "Fixtures").glob("*"))
] if (ROOT / "Resources" / "Fixtures").exists() else []

all_paths = sorted(set(app_sources + widget_sources + test_sources + ui_test_sources + app_resources + test_resources + [
    "Config/Project.xcconfig",
    "Config/App-Info.plist",
    "Config/Widget-Info.plist",
    "Config/AI-Monitor.entitlements",
    "Config/AI-MonitorWidget.entitlements",
]))

file_types = {
    ".swift": "sourcecode.swift",
    ".plist": "text.plist.xml",
    ".xcconfig": "text.xcconfig",
    ".json": "text.json",
    ".xcstrings": "text.json.xcstrings",
    ".svg": "image.svg",
    ".png": "image.png",
}

refs: list[str] = []
children: list[str] = []
for path in all_paths:
    suffix = Path(path).suffix
    file_type = "folder.assetcatalog" if suffix == ".xcassets" else file_types.get(suffix, "text")
    refs.append(f"\t\t{oid('ref:'+path)} /* {Path(path).name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = {quote(path)}; sourceTree = SOURCE_ROOT; }};")
    children.append(f"\t\t\t\t{oid('ref:'+path)} /* {Path(path).name} */,")

products = {
    "app": ("AI Monitor.app", "wrapper.application"),
    "widget": ("AI Monitor Widget.appex", "wrapper.app-extension"),
    "tests": ("AI Monitor Tests.xctest", "wrapper.cfbundle"),
    "uitests": ("AI Monitor UI Tests.xctest", "wrapper.cfbundle"),
}
for key, (name, file_type) in products.items():
    refs.append(f"\t\t{oid('product:'+key)} /* {name} */ = {{isa = PBXFileReference; explicitFileType = {file_type}; includeInIndex = 0; path = {quote(name)}; sourceTree = BUILT_PRODUCTS_DIR; }};")

build_files: list[str] = []


def phase_entries(target: str, paths: list[str], role: str) -> list[str]:
    result = []
    for path in paths:
        key = f"build:{target}:{role}:{path}"
        build_files.append(f"\t\t{oid(key)} /* {Path(path).name} in {role.title()} */ = {{isa = PBXBuildFile; fileRef = {oid('ref:'+path)} /* {Path(path).name} */; }};")
        result.append(f"\t\t\t\t{oid(key)} /* {Path(path).name} in {role.title()} */,")
    return result


app_source_entries = phase_entries("app", app_sources, "sources")
widget_source_entries = phase_entries("widget", widget_sources, "sources")
widget_resource_entries = phase_entries("widget", ["Resources/Localizable.xcstrings"], "resources")
test_source_entries = phase_entries("tests", test_sources, "sources")
ui_test_source_entries = phase_entries("uitests", ui_test_sources, "sources")
app_resource_entries = phase_entries("app", app_resources, "resources")
test_resource_entries = phase_entries("tests", test_resources, "resources")

embed_key = "build:app:embed:widget"
build_files.append(
    f"\t\t{oid(embed_key)} /* AI Monitor Widget.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {oid('product:widget')} /* AI Monitor Widget.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};"
)

project_id = oid("project")
main_group = oid("group:main")
products_group = oid("group:products")
app_target = oid("target:app")
widget_target = oid("target:widget")
tests_target = oid("target:tests")
ui_tests_target = oid("target:uitests")


def build_phase(target: str, kind: str, entries: list[str]) -> str:
    isa = {"sources": "PBXSourcesBuildPhase", "resources": "PBXResourcesBuildPhase", "frameworks": "PBXFrameworksBuildPhase"}[kind]
    return f"""\t\t{oid(f'phase:{target}:{kind}')} /* {kind.title()} */ = {{
\t\t\tisa = {isa};
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(entries)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""


phases = [
    build_phase("app", "sources", app_source_entries),
    build_phase("app", "frameworks", []),
    build_phase("app", "resources", app_resource_entries),
    build_phase("widget", "sources", widget_source_entries),
    build_phase("widget", "frameworks", []),
    build_phase("widget", "resources", widget_resource_entries),
    build_phase("tests", "sources", test_source_entries),
    build_phase("tests", "frameworks", []),
    build_phase("tests", "resources", test_resource_entries),
    build_phase("uitests", "sources", ui_test_source_entries),
    build_phase("uitests", "frameworks", []),
    build_phase("uitests", "resources", []),
]

embed_phase = f"""\t\t{oid('phase:app:embed')} /* Embed App Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = ({oid(embed_key)} /* AI Monitor Widget.appex in Embed App Extensions */, );
\t\t\tname = "Embed App Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};"""

dependency_proxy = oid("proxy:app-widget")
dependency = oid("dependency:app-widget")
ui_dependency_proxy = oid("proxy:uitests-app")
ui_dependency = oid("dependency:uitests-app")


def config(config_key: str, name: str, settings: dict[str, str], base: bool = True) -> str:
    values = "\n".join(f"\t\t\t\t{k} = {v};" for k, v in settings.items())
    base_line = f"\n\t\t\tbaseConfigurationReference = {oid('ref:Config/Project.xcconfig')} /* Project.xcconfig */;" if base else ""
    return f"""\t\t{oid(config_key)} /* {name} */ = {{
\t\t\tisa = XCBuildConfiguration;{base_line}
\t\t\tbuildSettings = {{
{values}
\t\t\t}};
\t\t\tname = {name};
\t\t}};"""


project_settings = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "COPY_PHASE_STRIP": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "SWIFT_STRICT_CONCURRENCY": "targeted",
}

app_settings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_ENTITLEMENTS": "Config/AI-Monitor.entitlements",
    "CODE_SIGN_STYLE": '"$(AIMONITOR_CODE_SIGN_STYLE)"',
    "COMBINE_HIDPI_IMAGES": "YES",
    "ENABLE_HARDENED_RUNTIME": "YES",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "Config/App-Info.plist",
    "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/../Frameworks"',
    "PRODUCT_BUNDLE_IDENTIFIER": '"$(AIMONITOR_BUNDLE_ID)"',
    "PRODUCT_NAME": '"AI Monitor"',
    "PROVISIONING_PROFILE_SPECIFIER": '"$(AIMONITOR_APP_PROFILE)"',
    "SWIFT_EMIT_LOC_STRINGS": "YES",
}
widget_settings = {
    "APPLICATION_EXTENSION_API_ONLY": "YES",
    "CODE_SIGN_ENTITLEMENTS": "Config/AI-MonitorWidget.entitlements",
    "CODE_SIGN_STYLE": '"$(AIMONITOR_CODE_SIGN_STYLE)"',
    "ENABLE_HARDENED_RUNTIME": "YES",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "Config/Widget-Info.plist",
    "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/../Frameworks @executable_path/../../../../Frameworks"',
    "PRODUCT_BUNDLE_IDENTIFIER": '"$(AIMONITOR_WIDGET_BUNDLE_ID)"',
    "PRODUCT_NAME": '"AI Monitor Widget"',
    "PROVISIONING_PROFILE_SPECIFIER": '"$(AIMONITOR_WIDGET_PROFILE)"',
    "SKIP_INSTALL": "YES",
}
test_settings = {
    "CODE_SIGNING_ALLOWED": "NO",
    "GENERATE_INFOPLIST_FILE": "YES",
    "PRODUCT_BUNDLE_IDENTIFIER": "dev.aimonitor.tests",
    "PRODUCT_NAME": '"AI Monitor Tests"',
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"$(inherited) TESTING"',
}
ui_test_settings = {
    "CODE_SIGNING_ALLOWED": "NO",
    "GENERATE_INFOPLIST_FILE": "YES",
    "PRODUCT_BUNDLE_IDENTIFIER": "dev.aimonitor.uitests",
    "PRODUCT_NAME": '"AI Monitor UI Tests"',
    "TEST_TARGET_NAME": '"AI-Monitor"',
}

configs = [
    config("config:project:debug", "Debug", {**project_settings, "DEBUG_INFORMATION_FORMAT": "dwarf", "ENABLE_TESTABILITY": "YES", "GCC_OPTIMIZATION_LEVEL": "0", "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"'}),
    config("config:project:release", "Release", {**project_settings, "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"', "SWIFT_COMPILATION_MODE": "wholemodule"}),
    config("config:app:debug", "Debug", {**app_settings, "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"$(inherited) DEBUG"'}),
    config("config:app:release", "Release", app_settings),
    config("config:widget:debug", "Debug", {**widget_settings, "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"$(inherited) DEBUG"'}),
    config("config:widget:release", "Release", widget_settings),
    config("config:tests:debug", "Debug", test_settings),
    config("config:tests:release", "Release", test_settings),
    config("config:uitests:debug", "Debug", ui_test_settings),
    config("config:uitests:release", "Release", ui_test_settings),
]


def config_list(key: str, configs_for_list: list[str]) -> str:
    entries = "\n".join(f"\t\t\t\t{oid(value)} /* {value.rsplit(':', 1)[-1].title()} */," for value in configs_for_list)
    return f"""\t\t{oid(key)} /* Build configuration list */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
{entries}
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};"""


configuration_lists = [
    config_list("configlist:project", ["config:project:debug", "config:project:release"]),
    config_list("configlist:app", ["config:app:debug", "config:app:release"]),
    config_list("configlist:widget", ["config:widget:debug", "config:widget:release"]),
    config_list("configlist:tests", ["config:tests:debug", "config:tests:release"]),
    config_list("configlist:uitests", ["config:uitests:debug", "config:uitests:release"]),
]


def target(key: str, name: str, product_key: str, product_type: str, phase_target: str, configlist: str, dependencies: list[str] | None = None) -> str:
    dependency_ids = {"widget": dependency, "app": ui_dependency}
    dependency_line = " ".join(f"{dependency_ids[item]} /* PBXTargetDependency */," for item in (dependencies or []))
    phases_for_target = ["sources", "frameworks", "resources"]
    phase_lines = [f"\t\t\t\t{oid(f'phase:{phase_target}:{kind}')} /* {kind.title()} */," for kind in phases_for_target]
    if key == "app":
        phase_lines.append(f"\t\t\t\t{oid('phase:app:embed')} /* Embed App Extensions */,")
    return f"""\t\t{oid('target:'+key)} /* {name} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {oid(configlist)} /* Build configuration list */;
\t\t\tbuildPhases = (
{chr(10).join(phase_lines)}
\t\t\t);
\t\t\tbuildRules = ( );
\t\t\tdependencies = ({dependency_line});
\t\t\tname = {quote(name)};
\t\t\tproductName = {quote(name)};
\t\t\tproductReference = {oid('product:'+product_key)} /* {products[product_key][0]} */;
\t\t\tproductType = {quote(product_type)};
\t\t}};"""


targets = [
    target("app", "AI-Monitor", "app", "com.apple.product-type.application", "app", "configlist:app", ["widget"]),
    target("widget", "AI-MonitorWidget", "widget", "com.apple.product-type.app-extension", "widget", "configlist:widget"),
    target("tests", "AI-MonitorTests", "tests", "com.apple.product-type.bundle.unit-test", "tests", "configlist:tests"),
    target("uitests", "AI-MonitorUITests", "uitests", "com.apple.product-type.bundle.ui-testing", "uitests", "configlist:uitests", ["app"]),
]

pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{}};
\tobjectVersion = 60;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
\t\t{dependency_proxy} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {project_id} /* Project object */; proxyType = 1; remoteGlobalIDString = {widget_target}; remoteInfo = AI-MonitorWidget; }};
\t\t{ui_dependency_proxy} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {project_id} /* Project object */; proxyType = 1; remoteGlobalIDString = {app_target}; remoteInfo = AI-Monitor; }};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
{embed_phase}
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
{chr(10).join(refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
{chr(10).join(p for p in phases if "PBXFrameworksBuildPhase" in p)}
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group} = {{isa = PBXGroup; children = (
{chr(10).join(children)}
\t\t\t\t{products_group} /* Products */,
\t\t\t); sourceTree = "<group>"; }};
\t\t{products_group} /* Products */ = {{isa = PBXGroup; children = (
\t\t\t\t{oid('product:app')} /* AI Monitor.app */,
\t\t\t\t{oid('product:widget')} /* AI Monitor Widget.appex */,
\t\t\t\t{oid('product:tests')} /* AI Monitor Tests.xctest */,
\t\t\t\t{oid('product:uitests')} /* AI Monitor UI Tests.xctest */,
\t\t\t); name = Products; sourceTree = "<group>"; }};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
{chr(10).join(targets)}
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2610; LastUpgradeCheck = 2610; TargetAttributes = {{
\t\t\t\t{app_target} = {{CreatedOnToolsVersion = 26.1; }};
\t\t\t\t{widget_target} = {{CreatedOnToolsVersion = 26.1; }};
\t\t\t\t{tests_target} = {{CreatedOnToolsVersion = 26.1; }};
\t\t\t\t{ui_tests_target} = {{CreatedOnToolsVersion = 26.1; TestTargetID = {app_target}; }};
\t\t\t}}; }};
\t\t\tbuildConfigurationList = {oid('configlist:project')} /* Build configuration list */;
\t\t\tcompatibilityVersion = "Xcode 15.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, "pt-BR", Base, );
\t\t\tmainGroup = {main_group};
\t\t\tproductRefGroup = {products_group} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = ({app_target} /* AI-Monitor */, {widget_target} /* AI-MonitorWidget */, {tests_target} /* AI-MonitorTests */, {ui_tests_target} /* AI-MonitorUITests */, );
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
{chr(10).join(p for p in phases if "PBXResourcesBuildPhase" in p)}
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
{chr(10).join(p for p in phases if "PBXSourcesBuildPhase" in p)}
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t{dependency} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {widget_target} /* AI-MonitorWidget */; targetProxy = {dependency_proxy} /* PBXContainerItemProxy */; }};
\t\t{ui_dependency} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {app_target} /* AI-Monitor */; targetProxy = {ui_dependency_proxy} /* PBXContainerItemProxy */; }};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
{chr(10).join(configs)}
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
{chr(10).join(configuration_lists)}
/* End XCConfigurationList section */
\t}};
\trootObject = {project_id} /* Project object */;
}}
"""

PROJECT.mkdir(exist_ok=True)
(PROJECT / "project.pbxproj").write_text(pbx)
scheme_dir = PROJECT / "xcshareddata" / "xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2610" version="1.7">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
  <BuildActionEntries>
   <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
    <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="AI Monitor.app" BlueprintName="AI-Monitor" ReferencedContainer="container:AI-Monitor.xcodeproj"/>
   </BuildActionEntry>
  </BuildActionEntries>
 </BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
  <Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{tests_target}" BuildableName="AI Monitor Tests.xctest" BlueprintName="AI-MonitorTests" ReferencedContainer="container:AI-Monitor.xcodeproj"/></TestableReference></Testables>
 </TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
  <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="AI Monitor.app" BlueprintName="AI-Monitor" ReferencedContainer="container:AI-Monitor.xcodeproj"/></BuildableProductRunnable>
 </LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="AI Monitor.app" BlueprintName="AI-Monitor" ReferencedContainer="container:AI-Monitor.xcodeproj"/></BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
(scheme_dir / "AI-Monitor.xcscheme").write_text(scheme)
ui_scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2610" version="1.7">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
  <BuildActionEntries>
   <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="YES">
    <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="AI Monitor.app" BlueprintName="AI-Monitor" ReferencedContainer="container:AI-Monitor.xcodeproj"/>
   </BuildActionEntry>
  </BuildActionEntries>
 </BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
  <Testables><TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ui_tests_target}" BuildableName="AI Monitor UI Tests.xctest" BlueprintName="AI-MonitorUITests" ReferencedContainer="container:AI-Monitor.xcodeproj"/></TestableReference></Testables>
 </TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
  <BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{app_target}" BuildableName="AI Monitor.app" BlueprintName="AI-Monitor" ReferencedContainer="container:AI-Monitor.xcodeproj"/></BuildableProductRunnable>
 </LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''
(scheme_dir / "AI-Monitor-UI-Tests.xcscheme").write_text(ui_scheme)
print(f"Generated {PROJECT.relative_to(ROOT)} with {len(app_sources)} app, {len(widget_sources)} widget, {len(test_sources)} unit-test, and {len(ui_test_sources)} UI-test source entries.")
