.items[] | select(.status.phase != "Running") | {name: .metadata.name, phase: .status.phase}
