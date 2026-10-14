/obj/item/sledgehammer
	name = "sledgehammer"
	desc = "A licensed replica of the hammer from that one commercial. The weight is real, you feel it in your wrists the moment you pick it up. Get it spinning and something on the other end is going to break."
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
	hitsound = SFX_SWING_HIT
	attack_verb_continuous = list("smashes", "slams", "bashes", "pounds")
	attack_verb_simple = list("smash", "slam", "bash", "pound")
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5)
	action_slots = ITEM_SLOT_HANDS
	actions_types = list(/datum/action/item_action/hammer_throw)
	var/force_wielded = 20
	var/knockback_range = 1
	var/list/spin_step_delays = list(
		0.4 SECONDS, 0.4 SECONDS, 0.3 SECONDS, 0.3 SECONDS,
		0.3 SECONDS, 0.2 SECONDS, 0.2 SECONDS, 0.2 SECONDS,
		0.1 SECONDS, 0.1 SECONDS, 0.1 SECONDS,
	)
	var/follow_through_delay = 0.15 SECONDS
	var/spinning = FALSE
	var/spin_timer
	var/spun_throw_in_flight = FALSE
	var/throwforce_before_spin
	var/spun_throwforce = 25
	var/spun_throw_range = 7
	var/spun_throw_knockdown = 2 SECONDS
	var/spin_dizziness = 4 SECONDS
	var/static/list/smashable_screen_types = typecacheof(list(
		/obj/machinery/computer,
		/obj/machinery/status_display,
	))
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
	add_deep_lore()

/obj/item/sledgehammer/proc/add_deep_lore()
	AddElement(/datum/element/examine_lore, \
		lore = "In 2584 a small computer company bought a single ad slot during the Sol Football Final. \
		Rows of grey workers sat in front of a giant telescreen while a droning executive read out \
		the Information Purification Directives. A woman in red shorts ran in past the guards, \
		spun twice and threw a sledgehammer straight through the screen.<br>\
		<br>\
		The computer sold modestly. The hammer sold out in a week.<br>\
		<br>\
		Nanotrasen now issues a licensed reproduction with the original weight and balance. \
		It is cleared for demolition and deconstruction work. It is not cleared for the briefing room telescreen. \
		That clause was added after the first shipment.<br>\
		<br>\
		Why 2584 will not be like \"1984\" is still pending review by the Nanotrasen ethics board." \
	) // for those who still dont get it https://youtu.be/ErwS24cBZPc

/obj/item/sledgehammer/update_icon_state()
	icon_state = "[base_icon_state]0"
	return ..()

/obj/item/sledgehammer/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(.)
		return .
	if(isliving(target))
		play_heavy_hitsound(target, user, attack_modifiers)
		return FALSE
	if(ismecha(target))
		playsound(target, pick(slam_sounds), 50)
	if(!iswallturf(target) || !HAS_TRAIT(src, TRAIT_WIELDED))
		return FALSE
	slam_wall(target, user)
	return TRUE

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

/obj/item/sledgehammer/proc/play_heavy_hitsound(mob/living/target_mob, mob/living/user, list/attack_modifiers)
	if(!HAS_TRAIT(src, TRAIT_WIELDED) || HAS_TRAIT(user, TRAIT_PACIFISM))
		return
	var/heavy_hitsound
	if(issilicon(target_mob)) // metal bonk
		heavy_hitsound = pick(metal_hitsounds)
	else if(iscarbon(target_mob))
		heavy_hitsound = 'sound/items/weapons/sledgehammer/heavy_hit.ogg'
	else
		return
	MUTE_ATTACK_HITSOUND(attack_modifiers)
	playsound(src, heavy_hitsound, get_clamped_volume(), TRUE, falloff_distance = 0)

/obj/item/sledgehammer/proc/knock_back(mob/living/target, mob/living/user)
	if(target.anchored)
		return
	var/atom/throw_target = get_edge_target_turf(target, get_dir(user, target))
	target.safe_throw_at(throw_target, knockback_range, 1, user, gentle = TRUE)

/obj/item/sledgehammer/proc/slam_wall(turf/closed/wall/wall, mob/living/user)
	user.changeNext_move(attack_speed)
	user.do_attack_animation(wall, used_item = src)

	if(istype(wall, /turf/closed/wall/r_wall) || wall.hardness <= /turf/closed/wall/r_wall::hardness || isindestructiblewall(wall))
		playsound(wall, pick(slam_sounds), 50, TRUE)
		wall.Shake(pixelshifty = 3, duration = 0.1 SECONDS, shake_interval = 0.1 SECONDS)
		user.visible_message(
			span_warning("[user] [pick(slam_verbs)] [src] against [wall], but it holds firm!"),
			span_warning("You slam [src] against [wall], but it is too sturdy to smash!"),
		)
		return

	var/wall_name = wall.name
	wall.AddComponent(/datum/component/torn_wall)
	if(iswallturf(wall))
		user.visible_message(
			span_danger("[user] [pick(slam_verbs)] [src] against [wall]!"),
			span_danger("You slam [src] against [wall]!"),
			span_hear("You hear a booming smash!"),
		)
		return
	user.visible_message(
		span_danger("[user] smashes through [wall_name] with [src]!"),
		span_danger("You smash through [wall_name]!"),
		span_hear("You hear a wall come crashing down!"),
	)

/obj/item/sledgehammer/proc/wind_up_throw(mob/living/user)
	if(spinning)
		return
	spinning = TRUE
	var/throw_direction = user.dir
	user.visible_message(
		span_warning("[user] starts spinning around with [src]!"),
		span_notice("You start spinning with [src]. Keep it up and let it fly."),
	)
	spin_timer = addtimer(CALLBACK(src, PROC_REF(spin_step), user, 1), spin_step_delays[1], TIMER_STOPPABLE)
	var/total_spin_time = 0
	for(var/step_delay in spin_step_delays)
		total_spin_time += step_delay
	var/spun_up = do_after(user, total_spin_time, user, extra_checks = CALLBACK(src, PROC_REF(is_wielded)))
	spinning = FALSE
	deltimer(spin_timer)
	spin_timer = null
	if(!spun_up)
		user.balloon_alert(user, "lost momentum!")
		return
	release_throw(user, throw_direction)

/obj/item/sledgehammer/proc/is_wielded()
	return HAS_TRAIT(src, TRAIT_WIELDED)

/obj/item/sledgehammer/proc/spin_step(mob/living/user, step_index)
	if(QDELETED(user))
		return
	user.setDir(turn(user.dir, -90))
	playsound(user, 'sound/items/weapons/thudswoosh.ogg', 20 + step_index * 3, TRUE)
	if(step_index < length(spin_step_delays))
		spin_timer = addtimer(CALLBACK(src, PROC_REF(spin_step), user, step_index + 1), spin_step_delays[step_index + 1], TIMER_STOPPABLE)

/// Lets go from the side, a quarter turn short, and momentum carries the thrower around to face the throw
/obj/item/sledgehammer/proc/release_throw(mob/living/user, throw_direction)
	var/datum/component/two_handed/grip = GetComponent(/datum/component/two_handed)
	grip.unwield(user, show_message = FALSE)
	if(!user.dropItemToGround(src, silent = TRUE))
		return
	var/release_direction = turn(throw_direction, 90)
	user.setDir(release_direction)
	addtimer(CALLBACK(src, PROC_REF(follow_through), user, release_direction, throw_direction), follow_through_delay)
	user.visible_message(
		span_danger("[user] lets [src] fly!"),
		span_danger("You let [src] fly!"),
	)
	playsound(user, 'sound/items/weapons/throwhard.ogg', 50, TRUE)
	user.set_dizzy_if_lower(spin_dizziness)
	user.log_message("spun up and threw [src] [dir2text(throw_direction)]", LOG_ATTACK)
	spun_throw_in_flight = TRUE
	throwforce_before_spin = throwforce
	throwforce = spun_throwforce
	var/turf/throw_target = get_ranged_target_turf(user, throw_direction, spun_throw_range)
	if(!throw_at(throw_target, spun_throw_range, throw_speed, user, spin = TRUE, callback = CALLBACK(src, PROC_REF(end_spun_throw))))
		end_spun_throw()

/obj/item/sledgehammer/proc/follow_through(mob/living/user, release_direction, throw_direction)
	if(user.dir == release_direction)
		user.setDir(throw_direction)

/obj/item/sledgehammer/proc/end_spun_throw()
	spun_throw_in_flight = FALSE
	throwforce = throwforce_before_spin

/obj/item/sledgehammer/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!spun_throw_in_flight || QDELETED(hit_atom))
		return
	if(isliving(hit_atom))
		if(loc == hit_atom)
			push_catcher(hit_atom, throwingdatum)
			return
		if(.)
			return
		var/mob/living/victim = hit_atom
		victim.Knockdown(spun_throw_knockdown)
		return
	if(is_type_in_typecache(hit_atom, smashable_screen_types))
		smash_screen(hit_atom)
		return
	for(var/obj/machinery/wall_screen in get_turf(src))
		if(!is_type_in_typecache(wall_screen, smashable_screen_types))
			continue
		var/datum/component/atom_mounted/mount = wall_screen.GetComponent(/datum/component/atom_mounted)
		if(!isnull(mount) && mount.hanging_support_atom == hit_atom)
			smash_screen(wall_screen)

/obj/item/sledgehammer/proc/push_catcher(mob/living/catcher, datum/thrownthing/throwingdatum)
	var/turf/catcher_turf = get_turf(catcher)
	catcher.Move(get_step(catcher_turf, throwingdatum.init_dir), throwingdatum.init_dir)
	log_combat(throwingdatum.get_thrower(), catcher, "pushed back with a caught spun throw of", src)
	if(get_turf(catcher) != catcher_turf)
		return
	var/knocked_down = catcher.Knockdown(SHOVE_KNOCKDOWN_SOLID, daze_amount = 3 SECONDS) // it shoves you into a wall
	catcher.visible_message(
		span_danger("[catcher] catches [src] and gets slammed into what is behind [catcher.p_them()][knocked_down ? ", going down" : ""]!"),
		span_userdanger("You catch [src], but it slams you back[knocked_down ? " and off your feet" : ""]!"),
		span_hear("You hear a loud thud!"),
	)

/obj/item/sledgehammer/proc/smash_screen(obj/machinery/screen)
	if(screen.resistance_flags & INDESTRUCTIBLE)
		return
	if(screen.atom_break(MELEE)) // and you'll see why 2584 won't be like 1984
		screen.visible_message(span_danger("[src] smashes straight through [screen]!"))

/obj/item/sledgehammer/throw_at(atom/target, range, speed, mob/thrower, spin = 1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	if(throwing && spun_throw_in_flight)
		end_spun_throw()
	return ..()

/datum/action/item_action/hammer_throw
	name = "Hammer Throw"
	desc = "Spin up with both hands and let the hammer fly. Telescreens hate this one trick."
	check_flags = parent_type::check_flags | AB_CHECK_IMMOBILE

/datum/action/item_action/hammer_throw/do_effect(trigger_flags)
	var/obj/item/sledgehammer/hammer = target
	if(!HAS_TRAIT(hammer, TRAIT_WIELDED))
		owner.balloon_alert(owner, "not dual-wielded!")
		return FALSE
	if(HAS_TRAIT(owner, TRAIT_PACIFISM) || HAS_TRAIT(owner, TRAIT_NO_THROWING) || HAS_TRAIT(hammer, TRAIT_NODROP))
		owner.balloon_alert(owner, "can't throw!")
		return FALSE
	INVOKE_ASYNC(hammer, TYPE_PROC_REF(/obj/item/sledgehammer, wind_up_throw), owner)
	return TRUE

/obj/item/sledgehammer/engineering
	name = "breaching sledgehammer"
	desc = "A demolition sledgehammer with a pick and a forked claw welded on, the kind firefighters call \"the irons\". Drive the claw into an airlock seam, put your weight behind it, and the airlock gives, powered or not."
	base_icon_state = "breaching_sledgehammer"
	icon_state = "breaching_sledgehammer0"
	worn_icon_state = "breaching_sledgehammer"
	usesound = 'sound/items/tools/jaws_pry.ogg'
	custom_materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT * 1.5,
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2.5,
	)
	var/static/list/forceable_door_types = typecacheof(list(
		/obj/machinery/door/airlock,
		/obj/machinery/door/firedoor,
		/obj/machinery/door/window,
	))

/obj/item/sledgehammer/engineering/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/cuffable_item)
	RegisterSignal(src, COMSIG_ITEM_INTERACTING_WITH_ATOM, PROC_REF(on_interacting_with_atom))

/obj/item/sledgehammer/engineering/add_deep_lore()
	AddElement(/datum/element/examine_lore, \
		lore = "Engineering asked for something that opens an airlock when the power is out, the access is wrong \
		and the jaws of life are on the other side of the fire.<br>\
		<br>\
		R&D welded a forcible entry bar onto a standard demolition hammer and called it a day. \
		The jaws of life are a precision instrument. This is not.<br>\
		<br>\
		It ships with a two-page guide on authorized use. The first page has never been read. \
		The second page is blank." \
	)

/obj/item/sledgehammer/engineering/examine(mob/user)
	. = ..()
	. += span_notice("Wield it and use it on an airlock outside of combat mode to force it open.")

/// Signal on ourselves, because doors grab the item in their own item_interaction before interact_with_atom gets a word in
/obj/item/sledgehammer/engineering/proc/on_interacting_with_atom(datum/source, mob/living/user, atom/target, list/modifiers)
	SIGNAL_HANDLER

	if(user.combat_mode || !is_type_in_typecache(target, forceable_door_types) || !HAS_TRAIT(src, TRAIT_WIELDED))
		return NONE
	var/obj/machinery/door/door = target
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, try_to_crowbar), src, user, TRUE)
	return ITEM_INTERACT_SUCCESS
