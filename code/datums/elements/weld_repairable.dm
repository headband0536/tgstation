/// Lets a machine be patched back up with a welder, broken or just dented
/datum/element/weld_repairable

/datum/element/weld_repairable/Attach(datum/target)
	. = ..()
	if(!ismachinery(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ATOM_TOOL_ACT(TOOL_WELDER), PROC_REF(on_welded))

/datum/element/weld_repairable/Detach(datum/source)
	UnregisterSignal(source, COMSIG_ATOM_TOOL_ACT(TOOL_WELDER))
	return ..()

/datum/element/weld_repairable/proc/on_welded(obj/machinery/machine, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER

	if(user.combat_mode)
		return NONE
	var/needs_repair = (machine.machine_stat & BROKEN) || machine.get_integrity() < machine.max_integrity
	if(!needs_repair)
		machine.balloon_alert(user, "it doesn't need repairs!")
		return ITEM_INTERACT_BLOCKING
	INVOKE_ASYNC(src, PROC_REF(repair), machine, user, tool)
	return ITEM_INTERACT_SUCCESS

/datum/element/weld_repairable/proc/repair(obj/machinery/machine, mob/living/user, obj/item/tool)
	user.balloon_alert_to_viewers("repairing...")
	if(!tool.use_tool(machine, user, 4 SECONDS, amount = 0, volume = 50))
		return
	machine.balloon_alert(user, "repaired")
	machine.repair_damage(machine.max_integrity - machine.get_integrity())
	machine.set_machine_stat(machine.machine_stat & ~BROKEN)
	machine.update_appearance()
