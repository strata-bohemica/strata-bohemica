extends RefCounted
## Applies (clip, clip time) to a skinned model. The only place that talks to AnimationPlayer.

var player: AnimationPlayer
var skeleton: Skeleton3D
var attachments: Array[BoneAttachment3D] = []

func _init(root: Node3D) -> void:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	player = players[0] if not players.is_empty() else null
	skeleton = skeletons[0] if not skeletons.is_empty() else null
	if player != null:
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for node in root.find_children("*", "BoneAttachment3D", true, false):
		attachments.append(node)

func has_clip(clip: String) -> bool:
	return player != null and player.has_animation(clip)

func apply(clip: String, clip_time: float) -> void:
	if not has_clip(clip):
		return
	skeleton.reset_bone_poses()
	player.play(clip)
	player.seek(clip_time, true)
	player.advance(0.0)
	skeleton.force_update_all_bone_transforms()
	for a in attachments:
		a.on_skeleton_update()
