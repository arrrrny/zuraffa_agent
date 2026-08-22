#!/usr/bin/env python3
import os
import re

di_dir = "/Users/ahmettok/Developer/zuraffa_agent/lib/src/di/usecases"
usecase_base = "/Users/ahmettok/Developer/zuraffa_agent/lib/src/domain/usecases"

# Get all actual usecase files
usecases = {}
for root, dirs, files in os.walk(usecase_base):
    for f in files:
        if f.endswith("_usecase.dart"):
            rel_root = os.path.relpath(root, usecase_base)
            if rel_root == ".":
                continue
            entity = rel_root.replace(os.sep, "_")
            class_name = f[:-5]  # remove .dart
            class_name_pascal = ''.join(word.capitalize() for word in class_name.split('_'))
            if entity not in usecases:
                usecases[entity] = []
            usecases[entity].append((class_name, class_name_pascal, rel_root))

# Special handling for engine usecases
engine_usecases = {}
if os.path.exists(os.path.join(usecase_base, "engine")):
    for f in os.listdir(os.path.join(usecase_base, "engine")):
        if f.endswith("_usecase.dart"):
            class_name = f[:-5]
            class_name_pascal = ''.join(word.capitalize() for word in class_name.split('_'))
            engine_usecases[class_name] = class_name_pascal

print("Found entities:", list(usecases.keys()))
print("Engine usecases:", list(engine_usecases.keys()))

# Map entity names in DI files to actual usecase directories
di_files = [f for f in os.listdir(di_dir) if f.endswith("_di.dart")]

for di_file in di_files:
    entity_name = di_file.replace("_usecase_di.dart", "")
    print(f"\nProcessing {di_file} -> entity: {entity_name}")
    
    # Find matching usecases
    matches = []
    
    # Check direct match
    if entity_name in usecases:
        matches = usecases[entity_name]
    # Check snake_case variations
    elif entity_name.replace("_", "") in usecases:
        matches = usecases[entity_name.replace("_", "")]
    # Check engine usecases
    elif entity_name == "engine_loop":
        # Engine loop has custom usecases
        matches = [
            ("execute_mission_usecase", "ExecuteMissionUseCase"),
            ("inject_steering_usecase", "InjectSteeringUseCase"),
            ("abort_mission_usecase", "AbortMissionUseCase"),
        ]
    elif entity_name == "agent_tool":
        matches = [
            ("get_tool_usecase", "GetToolUseCase"),
            ("list_tools_usecase", "ListToolsUseCase"),
        ]
    elif entity_name == "client_health":
        matches = [
            ("mark_failure_usecase", "MarkFailureUseCase"),
            ("is_healthy_usecase", "IsHealthyUseCase"),
        ]
    elif entity_name == "fallback_chain":
        matches = [
            ("select_provider_usecase", "SelectProviderUseCase"),
            ("record_failure_usecase", "RecordFailureUseCase"),
        ]
    elif entity_name == "golden_mission":
        matches = [
            ("record_golden_mission_usecase", "RecordGoldenMissionUseCase"),
            ("replay_golden_mission_usecase", "ReplayGoldenMissionUseCase"),
        ]
    elif entity_name == "suite":
        matches = [
            ("score_suite_usecase", "ScoreSuiteUseCase"),
            ("evaluate_suite_usecase", "EvaluateSuiteUseCase"),
        ]
    elif entity_name == "sub_agent_type":
        matches = [
            ("execute_sub_agent_usecase", "ExecuteSubAgentUseCase"),
        ]
    elif entity_name == "agent_spec":
        matches = [
            ("resolve_agent_spec_usecase", "ResolveAgentSpecUseCase"),
        ]
    else:
        # Try to find in entity-specific usecases
        snake = entity_name.replace("-", "_")
        for key in usecases:
            if key.replace("_", "") == snake.replace("_", ""):
                matches = usecases[key]
                break
    
    if not matches:
        print(f"  WARNING: No matches for {entity_name}")
        continue
    
    # Build imports
    imports = []
    registrations = []
    for class_name, class_name_pascal, _ in matches:
        if entity_name in ["engine_loop", "agent_tool", "client_health", "fallback_chain", "golden_mission", "suite", "sub_agent_type", "agent_spec"]:
            import_path = f"../../domain/usecases/engine/{class_name}.dart"
        else:
            # Find the directory for this entity
            dir_name = entity_name
            import_path = f"../../domain/usecases/{dir_name}/{class_name}.dart"
        imports.append(import_path)
        registrations.append(f"  getIt.registerLazySingleton<{class_name_pascal}>(() => {class_name_pascal}(getIt()));")
    
    # Write new DI file
    content = """// GENERATED - DO NOT EDIT
import 'package:zuraffa/zuraffa.dart';

"""
    for imp in imports:
        content += f"import '{imp}';\n"
    content += "\n"
    content += f"void register{entity_name.replace('_', ' ').title().replace(' ', '')}UseCase(GetIt getIt) {{\n"
    for reg in registrations:
        content += f"{reg}\n"
    content += "}\n\n// END GENERATED\n"
    
    filepath = os.path.join(di_dir, di_file)
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"  Fixed: {len(matches)} usecases")

print("\nDone!")