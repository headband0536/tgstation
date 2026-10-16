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
	var/structure_demolition_multiplier = 2 //yeah its realy for deconstruction works
	var/list/spin_step_delays = list(
		0.4 SECONDS, 0.4 SECONDS, 0.3 SECONDS, 0.3 SECONDS,
		0.3 SECONDS, 0.2 SECONDS, 0.2 SECONDS, 0.2 SECONDS,
		0.1 SECONDS, 0.1 SECONDS, 0.1 SECONDS,
	)
	var/follow_through_delay = 0.15 SECONDS
	var/spin_facing
	var/spin_timer
	var/spun_throw_in_flight = FALSE
	var/throwforce_before_spin
	var/spun_throwforce = 25
	var/spun_throw_range = 7
	var/spun_throw_knockdown = 2 SECONDS
	var/spin_dizziness = 4 SECONDS
	var/spin_stamina_cost = 30 // spreads over the whole spin
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
	RegisterSignal(src, COMSIG_SEND_ITEM_ATTACK_MESSAGE_OBJECT, PROC_REF(on_attack_message))
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
		var/mob/living/living_target = target
		if(living_target.body_position == STANDING_UP) // no shove stun chains
			user.disarm(living_target, src)
		return
	if(target.resistance_flags & INDESTRUCTIBLE)
		return
	if(istype(target, /obj/structure/window) || istype(target, /obj/structure/grille))
		target.atom_destruction(MELEE)

/obj/item/sledgehammer/get_demolition_modifier(obj/target)
	. = ..()
	if(!isstructure(target) || !HAS_TRAIT(src, TRAIT_WIELDED))
		return .
	if(HAS_TRAIT(target, TRAIT_IGNORE_DEMOLITION) || HAS_TRAIT(target, TRAIT_INVERTED_DEMOLITION))
		return .
	return . * structure_demolition_multiplier

/obj/item/sledgehammer/proc/on_attack_message(obj/item/source, mob/living/victim, mob/living/attacker)
	SIGNAL_HANDLER

	if(victim == attacker || victim.body_position != LYING_DOWN)
		return NONE
	// downward strike, like a kick
	var/attacker_name = (attacker in viewers(victim, null)) ? "[attacker]" : "Something"
	victim.visible_message(
		span_danger("[attacker_name] brings [src] down on [victim]!"),
		span_userdanger("[attacker_name] brings [src] down on you!"),
		span_hear("You hear a heavy thud!"),
		vision_distance = COMBAT_MESSAGE_RANGE,
		ignored_mobs = attacker,
	)
	to_chat(attacker, span_danger("You bring [src] down on [victim]!"))
	return SIGNAL_MESSAGE_MODIFIED

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

/obj/item/sledgehammer/proc/slam_wall(turf/closed/wall/wall, mob/living/user)
	user.changeNext_move(attack_speed)
	user.do_attack_animation(wall, used_item = src)

	if(istype(wall, /turf/closed/wall/r_wall) || wall.hardness <= /turf/closed/wall/r_wall::hardness || isindestructiblewall(wall))
		playsound(wall, pick(slam_sounds), 50, TRUE)
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
	if(spin_facing)
		return
	var/throw_direction = user.dir
	var/spin_turn_angle = IS_RIGHT_INDEX(user.get_held_index_of_item(src)) ? -90 : 90 // hammer trails, body drags it around
	spin_facing = throw_direction
	RegisterSignal(user, COMSIG_ATOM_PRE_DIR_CHANGE, PROC_REF(hold_spin_facing)) // so player can't 'break' spin 'anim'
	user.visible_message(
		span_warning("[user] starts spinning around with [src]!"),
		span_notice("You start spinning with [src]. Keep it up and let it fly."),
	)
	spin_timer = addtimer(CALLBACK(src, PROC_REF(spin_step), user, spin_turn_angle, 1), spin_step_delays[1], TIMER_STOPPABLE)
	var/total_spin_time = 0
	for(var/step_delay in spin_step_delays)
		total_spin_time += step_delay
	var/spun_up = do_after(user, total_spin_time, user, timed_action_flags = IGNORE_SLOWDOWNS, extra_checks = CALLBACK(src, PROC_REF(is_wielded)))
	spin_facing = null
	UnregisterSignal(user, COMSIG_ATOM_PRE_DIR_CHANGE)
	deltimer(spin_timer)
	spin_timer = null
	if(!spun_up)
		user.balloon_alert(user, "lost momentum!")
		return
	release_throw(user, throw_direction, spin_turn_angle)

/obj/item/sledgehammer/proc/is_wielded()
	return HAS_TRAIT(src, TRAIT_WIELDED)

/obj/item/sledgehammer/proc/hold_spin_facing(mob/living/source, old_dir, new_dir)
	SIGNAL_HANDLER

	if(new_dir != spin_facing)
		return COMPONENT_ATOM_BLOCK_DIR_CHANGE
	return NONE

/obj/item/sledgehammer/proc/spin_step(mob/living/user, spin_turn_angle, step_index)
	if(QDELETED(user))
		return
	spin_facing = turn(spin_facing, spin_turn_angle)
	user.setDir(spin_facing)
	user.adjust_stamina_loss(spin_stamina_cost / length(spin_step_delays))
	playsound(user, 'sound/items/weapons/thudswoosh.ogg', 20 + step_index * 3, TRUE)
	if(step_index < length(spin_step_delays))
		spin_timer = addtimer(CALLBACK(src, PROC_REF(spin_step), user, spin_turn_angle, step_index + 1), spin_step_delays[step_index + 1], TIMER_STOPPABLE)

/obj/item/sledgehammer/proc/release_throw(mob/living/user, throw_direction, spin_turn_angle)
	var/datum/component/two_handed/grip = GetComponent(/datum/component/two_handed)
	grip.unwield(user, show_message = FALSE)
	if(!user.dropItemToGround(src, silent = TRUE))
		return
	var/release_direction = turn(throw_direction, spin_turn_angle * length(spin_step_delays))
	user.setDir(release_direction)
	addtimer(CALLBACK(src, PROC_REF(follow_through), user, release_direction, throw_direction), follow_through_delay) // momentum spins the thrower
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
	var/turf/hit_turf = get_turf(hit_atom)
	for(var/obj/machinery/wall_screen as anything in typecache_filter_list(range(1, src), smashable_screen_types))
		if(get_turf_pixel(wall_screen) == hit_turf) // atom_mounted misses supply and brig displays, they're held up by pixel offsets
			smash_screen(wall_screen)

/obj/item/sledgehammer/proc/push_catcher(mob/living/catcher, datum/thrownthing/throwingdatum)
	var/turf/catcher_turf = get_turf(catcher)
	catcher.Move(get_step(catcher_turf, throwingdatum.init_dir), throwingdatum.init_dir)
	log_combat(throwingdatum.get_thrower(), catcher, "pushed back with a caught spun throw of", src)
	if(get_turf(catcher) != catcher_turf)
		return
	var/knocked_down = catcher.Knockdown(SHOVE_KNOCKDOWN_SOLID, daze_amount = 3 SECONDS) // it literally shoves you
	catcher.visible_message(
		span_danger("[catcher] catches [src] and gets slammed into what is behind [catcher.p_them()][knocked_down ? ", going down" : ""]!"),
		span_userdanger("You catch [src], but it slams you back[knocked_down ? " and off your feet" : ""]!"),
		span_hear("You hear a loud thud!"),
	)

/obj/item/sledgehammer/proc/smash_screen(obj/machinery/screen)
	if(screen.resistance_flags & INDESTRUCTIBLE)
		return
	if(screen.atom_break(MELEE)) // and you'll see why 2584 won't be like "1984"
		screen.visible_message(span_danger("[src] smashes straight through [screen]!"))

/obj/item/sledgehammer/throw_at(atom/target, range, speed, mob/thrower, spin = 1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE, quickstart = TRUE, throw_type_path = /datum/thrownthing)
	if(throwing && spun_throw_in_flight)
		end_spun_throw()
	return ..()

/datum/action/item_action/hammer_throw
	name = "Hammer Throw"
	desc = "Spin up with both hands and let the hammer fly. Telescreens hate this one trick."
	check_flags = parent_type::check_flags | AB_CHECK_IMMOBILE

/datum/action/item_action/hammer_throw/New(Target)
	. = ..()
	RegisterSignals(target, list(SIGNAL_ADDTRAIT(TRAIT_WIELDED), SIGNAL_REMOVETRAIT(TRAIT_WIELDED)), PROC_REF(update_status_on_signal))

/datum/action/item_action/hammer_throw/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	if(!HAS_TRAIT(target, TRAIT_WIELDED))
		if(feedback)
			owner.balloon_alert(owner, "not dual-wielded!")
		return FALSE
	return TRUE

/datum/action/item_action/hammer_throw/do_effect(trigger_flags)
	var/obj/item/sledgehammer/hammer = target
	if(HAS_TRAIT(owner, TRAIT_PACIFISM) || HAS_TRAIT(owner, TRAIT_NO_THROWING) || HAS_TRAIT(hammer, TRAIT_NODROP))
		owner.balloon_alert(owner, "can't throw!")
		return FALSE
	INVOKE_ASYNC(hammer, TYPE_PROC_REF(/obj/item/sledgehammer, wind_up_throw), owner)
	return TRUE
