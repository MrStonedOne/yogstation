
var/list/mob/living/simple_animal/borer/borers = list()
var/total_borer_hosts_needed = 10

/mob/living/simple_animal/borer
	name = "Cortical Borer"
	desc = "A small, quivering, slug-like creature."
	icon_state = "brainslug"
	icon_living = "brainslug"
	icon_dead = "brainslug_dead"
	health = 20
	maxHealth = 20
	melee_damage_lower = 5
	melee_damage_upper = 5
	attacktext = "chomps"
	attack_sound = 'sound/weapons/bite.ogg'
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	faction = list("creature")
	ventcrawler = 2
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500


	var/mob/living/carbon/victim = null
	var/mob/living/captive_brain/host_brain = null
	var/docile = 0
	var/controlling = 0
	var/chemicals = 50
	var/used_dominate
	var/used_control
	var/influence = 0
	var/borer_chems = list()
	var/dominate_cooldown = 150
	var/control_cooldown = 3000
	var/leaving = 0


/mob/living/simple_animal/borer/New()
	..()
	name = "[pick("Primary","Secondary","Tertiary","Quaternary")] Borer ([rand(100,999)])"
	borer_chems += /datum/borer_chem/mannitol
	borer_chems += /datum/borer_chem/bicaridine
	borer_chems += /datum/borer_chem/kelotane
	borer_chems += /datum/borer_chem/charcoal
	borer_chems += /datum/borer_chem/ephedrine
	borer_chems += /datum/borer_chem/leporazine
	borer_chems += /datum/borer_chem/perfluorodecalin
	borer_chems += /datum/borer_chem/spacedrugs
	borer_chems += /datum/borer_chem/mutadone
	borer_chems += /datum/borer_chem/creagent
	borer_chems += /datum/borer_chem/ethanol

	borers += src

/mob/living/simple_animal/borer/attack_ghost(mob/user)
	if(src.ckey)
		return
	var/be_swarmer = alert("Become a cortical borer? (Warning, You can no longer be cloned!)",,"Yes","No")
	if(be_swarmer == "No")
		return
	transfer_personality(user.client)

/mob/living/simple_animal/borer/Stat()
	..()

	if(statpanel("Status"))
		stat(null, "Chemicals: [chemicals]")
		if(victim)
			stat(null, "Influence: [influence]%")

/mob/living/simple_animal/borer/Life()

	..()

	if(victim)

		if(stat != UNCONSCIOUS && victim.stat != UNCONSCIOUS)
			if(chemicals < 250)
				chemicals++
			if(influence < 100)
				influence += 0.5
				if(influence == 100)
					src << "<span class='boldnotice'>You are one with [victim] you both aid eachother in their needs and establish a mutally beneficial relationship.</span>"
					victim << "<span class='boldnotice'>You are one with [src] you both aid eachother in their needs and establish a mutally beneficial relationship.</span>"
				if(influence == 80)
					victim << "<span class='boldnotice'>You feel [src]'s power grow to extreme levels. You beging to feel unbeatable.</span>"
				if(influence == 50)
					victim << "<span class='danger'>You don't feel like yourself.</span>"

		if(stat != DEAD && victim.stat != DEAD)

			if(victim.reagents.has_reagent("sugar"))
				if(!docile)
					if(controlling)
						victim << "<span class='boldnotice'>You feel the soporific flow of sugar in your host's blood, lulling you into docility.</span>"
					else
						src << "<span class='boldnotice'>You feel the soporific flow of sugar in your host's blood, lulling you into docility.</span>"
					docile = 1
					influence -= 1
			else
				if(docile)
					if(controlling)
						victim << "<span class='boldnotice'>You shake off your lethargy as the sugar leaves your host's blood.</span>"
					else
						src << "<span class='boldnotice'>You shake off your lethargy as the sugar leaves your host's blood.</span>"
					docile = 0
			if(controlling)

				if(docile)
					victim << "<span class='boldnotice'>You are feeling far too docile to continue controlling your host...</span>"
					victim.release_control()
					return

				if(prob(5))
					victim.adjustBrainLoss(rand(1,2))

				if(prob(victim.brainloss/20))
					victim.say("*[pick(list("blink","blink_r","choke","aflap","drool","twitch","twitch_s","gasp"))]")

/mob/living/simple_animal/borer/say(message)
	if(dd_hasprefix(message, ";"))
		message = copytext(message,2)
		for(var/borer in borers)
			borer << "<span class='borer'><b>HIVEMIND: </b>[name] says: \"[message]\""
		for(var/mob/dead in dead_mob_list)
			dead << "<span class='borer'><b>BORER HIVEMIND: </b>[name] says: \"[message]\""
		return
	if(!victim)
		src << "<span class='boldnotice'>You cannot speak without a host.</span>"
		return
	if(dd_hasprefix(message, "*"))
		message = copytext(message,2)
		victim.say(message)
		return
	if(influence > 80)
		victim << "<span class='green'><b>[name] telepathicaly shouts... </b></span><span class='userdanger'>[message]</span>"
		src << "<span class='green'><b>[name] telepathicaly shouts... </b></span><span class='userdanger'>[message]</span>"
	else if(influence > 40)
		victim << "<span class='green'><b>[name] telepathicaly says... </b></span>[message]"
		src << "<span class='green'><b>[name] telepathicaly says... </b></span>[message]"
	else
		victim << "<span class='green'><b>[name] telepathicaly whispers... </b></span><i>[message]</i>"
		src << "<span class='green'><b>[name] telepathicaly whispers... </b></span><i>[message]</i>"

/mob/living/simple_animal/borer/UnarmedAttack()
	return

/mob/living/simple_animal/borer/ex_act()
	if(victim)
		return

	..()

/mob/living/simple_animal/borer/proc/Infect(mob/living/carbon/victim)
	if(!victim)
		return

	if(victim.borer)
		src << "<span class='boldnotice'>[victim] is already infected!</span>"
		return

	if(!victim.key || !victim.mind || !victim.client)
		src << "<span class='boldnotice'>[victim]'s mind seems unresponsive. Try someone else!</span>"
		return

	update_borer_icons_add(victim)

	src.victim = victim
	victim.borer = src
	src.loc = victim

	log_game("[src]/([src.ckey]) has infected [victim]/([victim.ckey]")

/mob/living/simple_animal/borer/proc/leave_victim()
	if(!victim) return

	if(controlling)
		detatch()

	update_borer_icons_remove(victim)

	src.loc = get_turf(victim)

	victim.borer = null
	victim = null
	influence = 0

/mob/living/simple_animal/borer/proc/transfer_personality(var/client/candidate)
	if(!candidate || !candidate.mob)
		return

	var/datum/mind/M = create_borer_mind(candidate.ckey)
	M.transfer_to(src)

	candidate.mob = src

	if(src.mind)
		src.mind.assigned_role = "Cortical Borer"
		src.mind.special_role = "Cortical Borer"
		src.mind.store_memory("You <b>MUST</b> escape with atleast [total_borer_hosts_needed] borers with hosts on the shuttle.")


	update_borer_icons_add(src)

	src << "<span class='notice'>You are a cortical borer!</span> You are a brain slug that worms its way \
	into the head of its victim. Use stealth, persuasion and your powers of mind control to keep you, \
	your host and your eventual spawn safe and warm."
	src << "You can speak to your victim with <b>say</b> and your fellow borers by prefixing your message with ';'. Checkout your borer tab to see your powers as a borer."
	src << "You <b>MUST</b> escape with atleast [total_borer_hosts_needed] borers with hosts on the shuttle."
/mob/living/simple_animal/borer/proc/detatch()
	if(!victim || !controlling) return

	controlling = 0

	victim.verbs -= /mob/living/carbon/proc/release_control
	victim.verbs -= /mob/living/carbon/proc/spawn_larvae

	victim.med_hud_set_status()

	victim.cansuicide = 1

	if(host_brain)

		// these are here so bans and multikey warnings are not triggered on the wrong people when ckey is changed.
		// computer_id and IP are not updated magically on their own in offline mobs -walter0o

		// host -> self
		var/h2s_id = victim.computer_id
		var/h2s_ip= victim.lastKnownIP
		victim.computer_id = null
		victim.lastKnownIP = null

		src.ckey = victim.ckey
		src.mind = victim.mind


		if(!src.computer_id)
			src.computer_id = h2s_id

		if(!host_brain.lastKnownIP)
			src.lastKnownIP = h2s_ip

		// brain -> host
		var/b2h_id = host_brain.computer_id
		var/b2h_ip= host_brain.lastKnownIP
		host_brain.computer_id = null
		host_brain.lastKnownIP = null

		victim.ckey = host_brain.ckey

		victim.mind = host_brain.mind

		if(!victim.computer_id)
			victim.computer_id = b2h_id

		if(!victim.lastKnownIP)
			victim.lastKnownIP = b2h_ip

	log_game("[src]/([src.ckey]) released control of [victim]/([victim.ckey]")

	qdel(host_brain)

/proc/create_borer_mind(key)
	var/datum/mind/M = new /datum/mind(key)
	M.assigned_role = "Cortical Borer"
	M.special_role = "Cortical Borer"
	return M

/proc/update_borer_icons_add(mob/living/carbon/M)
	var/datum/atom_hud/antag/borer_hud = huds[ANTAG_HUD_BORER]
	borer_hud.join_hud(M)
	ticker.mode.set_antag_hud(M, "borer")

/proc/update_borer_icons_remove(mob/living/carbon/M)
	var/datum/atom_hud/antag/borer_hud = huds[ANTAG_HUD_BORER]
	borer_hud.leave_hud(M)
	ticker.mode.set_antag_hud(M, null)