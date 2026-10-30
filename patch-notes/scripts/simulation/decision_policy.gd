## Optional observation contract for an in-process decision policy. Plain
## Callables continue to receive the complete CampaignSession observation.
extends RefCounted

func observation(session: RefCounted) -> Dictionary:
	return session.observation()
