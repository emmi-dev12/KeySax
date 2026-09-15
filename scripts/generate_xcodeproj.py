#!/usr/bin/env python3
"""Generate KeySax.xcodeproj/project.pbxproj from the source tree."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJ = ROOT / "KeySax.xcodeproj"
SOURCES = ROOT / "KeySax"

SWIFT = sorted(p.relative_to(SOURCES) for p in SOURCES.rglob("*.swift"))


def uid(name: str) -> str:
    digest = hashlib.sha1(name.encode()).hexdigest()[:24].upper()
    return digest


def entry(path: Path) -> tuple[str, str, str]:
    ref = uid(f"ref:{path}")
    build = uid(f"build:{path}")
    return str(path), ref, build


files = [entry(p) for p in SWIFT]
asset_ref = uid("ref:Assets.xcassets")
asset_build = uid("build:Assets.xcassets")
icns_ref = uid("ref:AppIcon.icns")
icns_build = uid("build:AppIcon.icns")
plist_ref = uid("ref:Info.plist")
ent_ref = uid("ref:KeySax.entitlements")

app_group = uid("group:app")
src_group = uid("group:src")
audio_group = uid("group:audio")
music_group = uid("group:music")
input_group = uid("group:input")
midi_group = uid("group:midi")
ui_group = uid("group:ui")
res_group = uid("group:res")
prod_group = uid("group:products")
fw_group = uid("group:fw")
target_id = uid("target:KeySax")
project_id = uid("project:KeySax")
sources_phase = uid("phase:sources")
resources_phase = uid("phase:resources")
frameworks_phase = uid("phase:frameworks")
proj_cfg_list = uid("cfgs:project")
tgt_cfg_list = uid("cfgs:target")
proj_debug = uid("cfg:project:debug")
proj_release = uid("cfg:project:release")
tgt_debug = uid("cfg:target:debug")
tgt_release = uid("cfg:target:release")
product_ref = uid("ref:KeySax.app")

frameworks = [
    "SwiftUI.framework",
    "AVFoundation.framework",
    "CoreMIDI.framework",
    "Accelerate.framework",
    "AudioToolbox.framework",
    "CoreAudio.framework",
    "AppKit.framework",
    "UniformTypeIdentifiers.framework",
    "Carbon.framework",
]
fw_refs = {name: (uid(f"ref:{name}"), uid(f"build:{name}")) for name in frameworks}

groups = {
    "App": [],
    "Audio": [],
    "Music": [],
    "Input": [],
    "MIDI": [],
    "UI": [],
    ".": [],
}
for path, ref, _ in files:
    parent = str(Path(path).parent)
    groups.setdefault(parent, []).append((path, ref))

build_files = "\n".join(
    f"\t\t{build} /* {path} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {path} */; }};"
    for path, ref, build in files
)
build_files += f"\n\t\t{asset_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {asset_ref} /* Assets.xcassets */; }};"
build_files += f"\n\t\t{icns_build} /* AppIcon.icns in Resources */ = {{isa = PBXBuildFile; fileRef = {icns_ref} /* AppIcon.icns */; }};"
for name, (ref, build) in fw_refs.items():
    build_files += f"\n\t\t{build} /* {name} in Frameworks */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};"

file_refs = "\n".join(
    f"\t\t{ref} /* {path} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {Path(path).name}; sourceTree = \"<group>\"; }};"
    for path, ref, _ in files
)
file_refs += f"""
\t\t{asset_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
\t\t{icns_ref} /* AppIcon.icns */ = {{isa = PBXFileReference; lastKnownFileType = image.icns; path = AppIcon.icns; sourceTree = "<group>"; }};
\t\t{plist_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
\t\t{ent_ref} /* KeySax.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = KeySax.entitlements; sourceTree = "<group>"; }};
\t\t{product_ref} /* KeySax.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = KeySax.app; sourceTree = BUILT_PRODUCTS_DIR; }};"""
for name, (ref, _) in fw_refs.items():
    file_refs += f"\n\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {name}; path = System/Library/Frameworks/{name}; sourceTree = SDKROOT; }};"


def group_children(folder: str) -> str:
    items = []
    for path, ref in groups.get(folder, []):
        items.append(f"\t\t\t\t{ref} /* {Path(path).name} */,")
    return "\n".join(items)


sources_list = "\n".join(
    f"\t\t\t\t{build} /* {path} in Sources */," for path, _, build in files
)
fw_list = "\n".join(
    f"\t\t\t\t{build} /* {name} in Frameworks */," for name, (_, build) in fw_refs.items()
)

root_swift = group_children(".")

pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{build_files}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{file_refs}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
{fw_list}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{app_group} /* KeySax */ = {{
			isa = PBXGroup;
			children = (
				{uid("group:App")} /* App */,
				{uid("group:Audio")} /* Audio */,
				{uid("group:Music")} /* Music */,
				{uid("group:Input")} /* Input */,
				{uid("group:MIDI")} /* MIDI */,
				{uid("group:UI")} /* UI */,
				{uid("group:Resources")} /* Resources */,
				{asset_ref} /* Assets.xcassets */,
				{plist_ref} /* Info.plist */,
				{ent_ref} /* KeySax.entitlements */,
{root_swift}
			);
			path = KeySax;
			sourceTree = "<group>";
		}};
		{uid("group:App")} /* App */ = {{
			isa = PBXGroup;
			children = (
{group_children("App")}
			);
			path = App;
			sourceTree = "<group>";
		}};
		{uid("group:Audio")} /* Audio */ = {{
			isa = PBXGroup;
			children = (
{group_children("Audio")}
			);
			path = Audio;
			sourceTree = "<group>";
		}};
		{uid("group:Music")} /* Music */ = {{
			isa = PBXGroup;
			children = (
{group_children("Music")}
			);
			path = Music;
			sourceTree = "<group>";
		}};
		{uid("group:Input")} /* Input */ = {{
			isa = PBXGroup;
			children = (
{group_children("Input")}
			);
			path = Input;
			sourceTree = "<group>";
		}};
		{uid("group:MIDI")} /* MIDI */ = {{
			isa = PBXGroup;
			children = (
{group_children("MIDI")}
			);
			path = MIDI;
			sourceTree = "<group>";
		}};
		{uid("group:UI")} /* UI */ = {{
			isa = PBXGroup;
			children = (
{group_children("UI")}
			);
			path = UI;
			sourceTree = "<group>";
		}};
		{uid("group:Resources")} /* Resources */ = {{
			isa = PBXGroup;
			children = (
				{icns_ref} /* AppIcon.icns */,
			);
			path = Resources;
			sourceTree = "<group>";
		}};
		{prod_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* KeySax.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{fw_group} /* Frameworks */ = {{
			isa = PBXGroup;
			children = (
""" + "\n".join(f"\t\t\t\t{ref} /* {name} */," for name, (ref, _) in fw_refs.items()) + f"""
			);
			name = Frameworks;
			sourceTree = "<group>";
		}};
		{uid("group:root")} = {{
			isa = PBXGroup;
			children = (
				{app_group} /* KeySax */,
				{fw_group} /* Frameworks */,
				{prod_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* KeySax */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {tgt_cfg_list} /* Build configuration list for PBXNativeTarget "KeySax" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = KeySax;
			productName = KeySax;
			productReference = {product_ref} /* KeySax.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2600;
				LastUpgradeCheck = 2600;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 26.0;
					}};
				}};
			}};
			buildConfigurationList = {proj_cfg_list} /* Build configuration list for PBXProject "KeySax" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {uid("group:root")};
			productRefGroup = {prod_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* KeySax */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{asset_build} /* Assets.xcassets in Resources */,
				{icns_build} /* AppIcon.icns in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{sources_list}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{proj_debug} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ARCHS = "arm64 x86_64";
				CLANG_ENABLE_MODULES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				MACOSX_DEPLOYMENT_TARGET = 27.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 6.0;
			}};
			name = Debug;
		}};
		{proj_release} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ARCHS = "arm64 x86_64";
				CLANG_ENABLE_MODULES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				MACOSX_DEPLOYMENT_TARGET = 27.0;
				ONLY_ACTIVE_ARCH = NO;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 6.0;
			}};
			name = Release;
		}};
		{tgt_debug} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = KeySax/KeySax.entitlements;
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_HARDENED_RUNTIME = NO;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = KeySax/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = "@executable_path/../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = 27.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.keysax.app;
				PRODUCT_NAME = KeySax;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
			}};
			name = Debug;
		}};
		{tgt_release} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_ENTITLEMENTS = KeySax/KeySax.entitlements;
				CODE_SIGN_IDENTITY = "-";
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = KeySax/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = "@executable_path/../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = 27.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.keysax.app;
				PRODUCT_NAME = KeySax;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 6.0;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{proj_cfg_list} /* Build configuration list for PBXProject "KeySax" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{proj_debug} /* Debug */,
				{proj_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{tgt_cfg_list} /* Build configuration list for PBXNativeTarget "KeySax" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{tgt_debug} /* Debug */,
				{tgt_release} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_id} /* Project object */;
}}
"""

PROJ.mkdir(parents=True, exist_ok=True)
(PROJ / "project.pbxproj").write_text(pbx)
print(f"Wrote {PROJ / 'project.pbxproj'} with {len(SWIFT)} Swift files")
