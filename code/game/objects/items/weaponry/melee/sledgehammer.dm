/obj/item/sledgehammer
	name = "sledgehammer"
	desc = "Steel head, hickory handle, no moving parts. It does not care whether it hits a wall, a window or a skull, as long as you swing it with both hands. A sticker on the handle reads: FOR STRUCTURAL USE ONLY."
	icon = 'icons/obj/weapons/sledgehammer.dmi'
	icon_state = "sledgehammer0"
	base_icon_state = "sledgehammer"
	lefthand_file = 'icons/mob/inhands/weapons/sledgehammer_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/sledgehammer_righthand.dmi'
	worn_icon = 'icons/mob/clothing/back/sledgehammer.dmi'
	worn_icon_state = "sledgehammer"
	force = 8
	throwforce = 10
	demolition_mod = 1.5
	attack_speed = 1.2 SECONDS
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	obj_flags = CONDUCTS_ELECTRICITY
	resistance_flags = FIRE_PROOF
	armor_type = /datum/armor/item_fireaxe
	sharpness = NONE
	hitsound = SFX_SWING_HIT
	attack_verb_continuous = list("smashes", "slams", "bashes", "pounds")
	attack_verb_simple = list("smash", "slam", "bash", "pound")
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5)
	var/force_wielded = 20
	var/lore = "\
		The second generation of the Nanotrasen demolition sledgehammer was designed \
		with crew safety as the highest priority.<br>\
		<br>\
		The head is now forged in one piece and no longer flies off mid-swing. \
		The handle is longer, keeping the user's own knees out of the striking arc. \
		The grip is wrapped in rubber, which the safety department lists as electrical insulation. \
		The head is still solid steel.<br>\
		<br>\
		In internal trials the new model cut workplace injuries by a third. \
		The remaining injuries are classified as user error."
	var/knockback_range = 1
	var/wall_hits_to_smash = 4
	var/reinforced_wall_hits_to_smash
	var/turf/closed/wall/dented_wall
	var/hits_on_dented_wall = 0
	var/static/list/slam_verbs = list("slams", "smashes", "rams")
	var/static/list/slam_sounds = list('sound/effects/meteorimpact.ogg', 'sound/effects/bang.ogg')
	var/static/list/metal_hitsounds = list(
		'sound/items/weapons/sledgehammer/metal_hit.ogg',
		'sound/items/weapons/sledgehammer/metal_hit2.ogg',
	)

/obj/item/sledgehammer/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, \
		force_unwielded = force, \
		force_wielded = force_wielded, \
		icon_wielded = "[base_icon_state]1", \
	)
	AddElement(/datum/element/examine_lore, lore = lore)

/obj/item/sledgehammer/update_icon_state()
	icon_state = "[base_icon_state]0"
	return ..()

/obj/item/sledgehammer/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(.)
		return .
	if(ismecha(target))
		playsound(target, pick(slam_sounds), 50)
	if(!iswallturf(target) || !HAS_TRAIT(src, TRAIT_WIELDED))
		return FALSE
	slam_wall(target, user)
	return TRUE

/obj/item/sledgehammer/attack(mob/living/target_mob, mob/living/user, list/modifiers, list/attack_modifiers)
	hitsound = pick_hitsound(target_mob)
	return ..()

/obj/item/sledgehammer/afterattack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	if(!HAS_TRAIT(src, TRAIT_WIELDED) || QDELETED(target))
		return
	if(isliving(target))
		knock_back(target, user)
		return
	if(target.resistance_flags & INDESTRUCTIBLE)
		return
	if(istype(target, /obj/structure/window) || istype(target, /obj/structure/grille))
		target.atom_destruction(MELEE)

/obj/item/sledgehammer/proc/pick_hitsound(mob/living/target_mob)
	if(!HAS_TRAIT(src, TRAIT_WIELDED))
		return SFX_SWING_HIT
	if(issilicon(target_mob))
		return pick(metal_hitsounds)
	if(iscarbon(target_mob))
		return 'sound/items/weapons/sledgehammer/heavy_hit.ogg'
	return SFX_SWING_HIT

/obj/item/sledgehammer/proc/knock_back(mob/living/target, mob/living/user)
	if(target.anchored)
		return
	var/atom/throw_target = get_edge_target_turf(target, get_dir(user, target))
	fling(target, throw_target, user)

/obj/item/sledgehammer/proc/fling(mob/living/target, atom/throw_target, mob/living/user)
	target.safe_throw_at(throw_target, knockback_range, 1, user, gentle = TRUE)

/obj/item/sledgehammer/proc/hits_to_smash(turf/closed/wall/wall)
	return istype(wall, /turf/closed/wall/r_wall) ? reinforced_wall_hits_to_smash : wall_hits_to_smash

/obj/item/sledgehammer/proc/slam_wall(turf/closed/wall/wall, mob/living/user)
	user.changeNext_move(attack_speed)
	user.do_attack_animation(wall, used_item = src)
	playsound(wall, pick(slam_sounds), 50, TRUE)
	wall.Shake(pixelshifty = 3, duration = 0.1 SECONDS, shake_interval = 0.1 SECONDS)

	var/hits_needed = hits_to_smash(wall)
	if((wall.resistance_flags & INDESTRUCTIBLE) || isnull(hits_needed))
		user.visible_message(
			span_warning("[user] [pick(slam_verbs)] [src] against [wall], but it holds firm!"),
			span_warning("You slam [src] against [wall], but it is too sturdy to smash!"),
		)
		return

	if(wall != dented_wall)
		dented_wall = wall
		hits_on_dented_wall = 0
	hits_on_dented_wall++

	if(hits_on_dented_wall < hits_needed)
		wall.add_dent(WALL_DENT_HIT)
		user.visible_message(
			span_danger("[user] [pick(slam_verbs)] [src] against [wall]!"),
			span_danger("You slam [src] against [wall]!"),
			span_hear("You hear a booming smash!"),
		)
		return

	dented_wall = null
	hits_on_dented_wall = 0
	user.visible_message(
		span_danger("[user] smashes through [wall] with [src]!"),
		span_danger("You smash through [wall]!"),
		span_hear("You hear a wall come crashing down!"),
	)
	wall.dismantle_wall(devastated = TRUE)

/obj/item/sledgehammer/engineering
	name = "breaching sledgehammer"
	desc = "A demolition sledgehammer with a pick and a forked claw welded on, the kind firefighters call \"the irons\". Drive the claw into an airlock seam, put your weight behind it, and the airlock gives, powered or not."
	icon = 'icons/obj/weapons/engineering_sledgehammer.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/engineering_sledgehammer_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/engineering_sledgehammer_righthand.dmi'
	worn_icon = 'icons/mob/clothing/back/engineering_sledgehammer.dmi'
	usesound = 'sound/items/tools/jaws_pry.ogg'
	custom_materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT * 1.5,
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2.5,
	)
	lore = "\
		Engineering asked for something that opens an airlock when the power is out, the access is wrong \
		and the jaws of life are on the other side of the fire.<br>\
		<br>\
		R&D welded a forcible entry bar onto a standard demolition hammer and called it a day. \
		The jaws of life are a precision instrument. This is not.<br>\
		<br>\
		It ships with a two-page guide on authorized use. The first page has never been read. \
		The second page is blank."
	var/static/list/forceable_door_types = typecacheof(list(
		/obj/machinery/door/airlock,
		/obj/machinery/door/firedoor,
		/obj/machinery/door/window,
	))

/obj/item/sledgehammer/engineering/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/cuffable_item)
	RegisterSignal(src, COMSIG_ITEM_INTERACTING_WITH_ATOM, PROC_REF(on_interacting_with_atom))

/obj/item/sledgehammer/engineering/examine(mob/user)
	. = ..()
	. += span_notice("Wield it and use it on an airlock outside of combat mode to force it open.")

/obj/item/sledgehammer/engineering/proc/on_interacting_with_atom(datum/source, mob/living/user, atom/target, list/modifiers)
	SIGNAL_HANDLER

	if(user.combat_mode || !is_type_in_typecache(target, forceable_door_types) || !HAS_TRAIT(src, TRAIT_WIELDED))
		return NONE
	var/obj/machinery/door/door = target
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, try_to_crowbar), src, user, TRUE)
	return ITEM_INTERACT_SUCCESS
