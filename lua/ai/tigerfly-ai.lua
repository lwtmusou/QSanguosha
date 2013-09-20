--技能：奢靡
local shemi_skill = {}
shemi_skill.name = "shemi" --只保证能否发动
table.insert(sgs.ai_skills, shemi_skill)
shemi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("ShemiAG") then return end
	local usenum = 2
	local usecard
	local hp = self.player:getHp()
	if hp <= 2 then usenum = 1 end
	local first_card, second_card 
	if self.player:getCards("he"):length() >= usenum then
		local flag = "he"
		if self:needToThrowArmor() and self.player:getArmor() then flag = "eh" 
			elseif self:getOverflow() > 0 then flag = "h" 
		end
		local cds = sgs.QList2Table(self.player:getCards(flag))
		local eid = self:getValuableCard(self.player) 
		self:sortByCardNeed(cds)
		for _, fcard in ipairs(cds) do
			if  not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo") or fcard:isKindOf("AmazingGrace")) and (fcard:getEffectiveId() ~= eid or not eid) then
				first_card = fcard
				if hp <= 2 then break end
				for _, scard in ipairs(cds) do
					if hp <= 2 then break end
					if first_card ~= scard and not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo") or scard:isKindOf("AmazingGrace")) and (scard:getEffectiveId() ~= eid or not eid) then
						second_card = scard
						local am = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0)
						am:addSubcard(first_card)
						am:addSubcard(second_card)
						local dummy_use = {isDummy = true}
						self:useTrickCard(am, dummy_use)
						if not dummy_use.card then first_card=nil;second_card=nil break end	
					end
				end
				if first_card and second_card then break end
			end
		end
	end
	if usenum == 2 then
		if first_card and second_card then
		local first_id, second_id =  first_card:getId(), second_card:getId()
		local amazing = sgs.Card_Parse(("amazing_grace:shemi[to_be_decided:0]=%d+%d"):format(first_id, second_id))
		assert(amazing)
		return amazing
		end
	else	
		 usecard = first_card 
		 if usecard then
			local usecardid = usecard:getId()
			local amazing = sgs.Card_Parse(("amazing_grace:shemi[to_be_decided:0]=%d"):format(usecardid))
			assert(amazing)
			return amazing
		end
	end	
end

--技能：宽惠
local function need_kuanhui(self, who)
	local card = sgs.Card_Parse(self.room:getTag("kuanhui_user"):toString())
	if card == nil then return false end
	local from = self.room:getCurrent()
	if self:isEnemy(who) then
		if card:isKindOf("GodSalvation") and who:isWounded() and self:hasTrickEffective(card, who, from) then
			if who:hasSkill("manjuan") and who:getPhase() == sgs.Player_NotActive then return true end
			if self:isWeak(who) then return true end
			if self:hasSkills(sgs.masochism_skill, who) then return true end
		end
		if card:isKindOf("AmazingGrace") and self:hasTrickEffective(card, who, from) then return true end
		return false
	elseif self:isFriend(who) then
		if who:hasSkill("noswuyan") and from:objectName() ~= who:objectName() then return true end
		if card:isKindOf("GodSalvation") and who:isWounded() and self:hasTrickEffective(card, who, from) then
			if self:needToLoseHp(who, nil, nil, true, true) then return true end
			return false
		end
		if card:isKindOf("IronChain") and (self:needKongcheng(who, true) or (who:isChained() and self:hasTrickEffective(card, who, from))) then
			return false
		end
		if card:isKindOf("AmazingGrace") and self:hasTrickEffective(card, who, from) and self:needKongcheng(who, true) then return true end
		if card:isKindOf("AmazingGrace") and self:hasTrickEffective(card, who, from) and not self:needKongcheng(who, true) then return false end
		if sgs.dynamic_value.benefit[card:getClassName()] == true then return false end
		return true
	end
end

function sgs.ai_skill_invoke.kuanhui(self, data)
	local effect = data:toCardUse()
	local tos = effect.to
	local invoke = false
	for _, to in sgs.qlist(tos) do
		if to and need_kuanhui(self, to) then invoke = true break end
	end
	return invoke
end

sgs.ai_skill_playerchosen.kuanhui = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defenseSlash")
	for _, player in ipairs(targets) do
	if player and need_kuanhui(self, player) then return player end
	end
end
sgs.ai_playerchosen_intention.kuanhui = function(self, from, to)
	local intention = -77
	local cardx = sgs.Card_Parse(self.room:getTag("kuanhui_user"):toString())
	if not cardx then return end
	if cardx:isKindOf("GodSalvation") and to:isWounded() and not self:needToLoseHp(to, nil, nil, true, true) then intention = 50 end
	if self:needKongcheng(to, true) then intention = 0 end
	if cardx:isKindOf("AmazingGrace") and self:hasTrickEffective(cardx, to) then intention = 0 end
	sgs.updateIntention(from, to, intention)
end


--技能：宏量
sgs.ai_skill_cardask["@HongliangGive"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.from
	local eid = self:getValuableCard(self.player) 
	if not target then return "." end
	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() <= 2 then
		if self.player:getHandcardNum() == 1 then
			local card = self.player:getHandcards():first()
			return (isCard("Jink", card, self.player)) and "." or ("$" .. card:getEffectiveId())
		end
		if self.player:getHandcardNum() == 2 then
			local first = self.player:getHandcards():first()
			local last = self.player:getHandcards():last()			
			local jink = isCard("Jink", first, self.player) and first or (isCard("Jink", last, self.player) and last)		
			if jink then
				return first:getEffectiveId() == jink:getEffectiveId() and ("$"..last:getEffectiveId()) or ("$"..first:getEffectiveId())
			end
		end		
	end
	if self:needToThrowArmor() and self.player:getArmor() then 
		return "$"..self.player:getArmor():getEffectiveId() 
	end
	if self:isFriend(target) then 
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByCardNeed(cards)
		if self:isWeak(target) then return "$"..cards[#cards]:getEffectiveId() end
		if self:isWeak() then
			for _, card in ipairs(cards) do
				if  card:isKindOf("Peach") or (card:getEffectiveId() == eid) then return "." end
			end
		else	
			return "$"..cards[1]:getEffectiveId() 
		end
	else
		local flag = "h"
		if self:hasSkills(sgs.lose_equip_skill) then flag = "eh" end
		local card2s = sgs.QList2Table(self.player:getCards(flag))
		self:sortByUseValue(card2s, true)
			for _, card in ipairs(card2s) do
				if not self:isValuableCard(card) and (card:getEffectiveId() ~= eid) then return "$"..card:getEffectiveId() end
			end
		end	
	return "." 
end


--技能：破阵
local pozhen_skill = {}
pozhen_skill.name = "pozhen"
table.insert(sgs.ai_skills, pozhen_skill)
pozhen_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("PozhenCard") then return sgs.Card_Parse("@RendeCard=.") end
end
sgs.ai_skill_use_func.PozhenCard = function(card,use,self)
	self:sort(self.enemies, "defense")
	self:sort(self.friends, "threat")
	for _, friend in ipairs(self.friends) do
		if friend and not friend:getEquips():isEmpty() and (friend:hasSkills(sgs.lose_equip_skill) or self:needToThrowArmor(friend)) and not self:willSkipPlayPhase(friend) then
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
	for _, friend in ipairs(self.friends) do
		if friend and not friend:getEquips():isEmpty() and friend:hasSkills(sgs.lose_equip_skill) then
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (not self.player:canSlash(enemy) or not self:needToThrowArmor(enemy) or self.player:distanceTo(enemy) > 1) and not enemy:getEquips():isEmpty() and enemy:getHandcardNum() < 3 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():isEmpty() then continue end
		if (not self.player:canSlash(enemy) or not self:needToThrowArmor(enemy) or self.player:distanceTo(enemy) > 1) and not enemy:hasSkills("kofxiaoji|xiaoji") then
			if not self:hasSuit("spade", true, enemy) then
				sgs.suit_for_ai = 0
				use.card =  card
				if use.to then use.to:append(enemy) end
				return
			end
			if not self:hasSuit("club", true, enemy) then
				sgs.suit_for_ai = 1
				use.card =  card
				if use.to then use.to:append(enemy) end
				return
			end
			if not self:hasSuit("diamond", true, enemy) then
				sgs.suit_for_ai = 3
				use.card =  card
				if use.to then use.to:append(enemy) end
				return
			end
			if not self:hasSuit("heart", true, enemy) then
				sgs.suit_for_ai = 2
				use.card =  card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	if zhugeliang and not self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 0 and not zhugeliang:getEquips():isEmpty() then
		use.card =  card
		if use.to then use.to:append(zhugeliang) end
			return
	end
	if self.player and self.player:isAlive() and not self.player:getEquips():isEmpty() then
		use.card =  card
		if use.to then use.to:append(self.player) end
		return
	end
end
sgs.ai_use_value.PozhenCard = 6.5
sgs.ai_use_priority.PozhenCard = 8

function sgs.ai_skill_suit.pozhen(self)
	local map = {0, 1, 2, 2, 2, 3}
	local suit = map[math.random(1, 6)]
	if sgs.suit_for_ai ~= nil and type(sgs.suit_for_ai) == "number" then return sgs.suit_for_ai end
	return suit 
end

sgs.ai_skill_cardask["@pozhen"] = function(self, data, pattern)
	local source = self.room:getTag("pozhen_source"):toPlayer()
	if not source or source:isDead() then return "." end
	if self:isFriend(source) then return "." end
	if source == self.player then return "." end
	if self:isEnemy(source) then 
		if not self:isWeak(source) and (self.player:hasSkills(sgs.lose_equip_skill) or self:needToThrowArmor()) then 
			return "." 
		end
	end
	local suits = pattern:split("|")[2]:split(",")
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByCardNeed(cards)
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) then
			for _, obname in ipairs(suits) do
				if card:getSuitString() == obname then return "$" .. card:getEffectiveId() end
			end
		end
	end
	return "."
end

--技能：化名
sgs.ai_skill_invoke["huaming"] = function(self,data)
	local source = self.room:getTag("huamingkiller"):toPlayer()
	return source 
end
 
sgs.ai_skill_choice["huaming"] = function(self, choices, data)
	local source = data:toPlayer()
	local orirole = self.role
	local sourole = source:getRole()
	if self:isFriend(source) then
		if sourole == "renegade" then return math.random(0, 1) == 1 and "renegade" or "loyalist" end
		return "rebel"
	else
		if source:isLord() then 
			return "loyalist"
		else
			return math.random(0, 1) == 1 and "renegade" or "loyalist"
		end
	end
	return orirole
end 

--技能：迫离

sgs.ai_skill_choice.poli = function(self, choices)
	local willdis = false
	local lightning = self:getCard("Lightning")
	if self.player:getMaxHp() == 1 or (lightning and not self:willUseLightning(lightning)) then willdis = true end
	if self:needToThrowArmor() or self:doNotDiscard(self.player) then willdis = true end
	if self:hasSkills(sgs.lose_equip_skill, self.player) and not self.player:getEquips():isEmpty() then willdis = true end
	return willdis and "discard" or "changehero"
end  

--技能：追袭


sgs.ai_skill_invoke.zhuixi = true

--技能：急思

function SmartAI:getAllnullNum(player, beenemy)
	player = player or self.player
	local n = 0
	if beenemy then
		for _, enemy in ipairs(self:getEnemies(player)) do
			local num = getCardsNum("Nullification", enemy)
			n = n + num
		end
	else
		for _, friend in ipairs(self:getFriends(player)) do
		local num = self.player:objectName() == friend:objectName() and self:getCardsNum("Nullification") or getCardsNum("Nullification", friend)
		n = n + num
		end
	end	
	return n
end
sgs.ai_skill_invoke.jisi = function(self, data) --大体上，根据无懈可击的使用方法...（好不麻烦）
	if self:getAllnullNum() > 0 and self:getAllnullNum() >= self:getAllnullNum(self.player, true) then return false end
	local effect = data:toCardEffect()
	local to = effect.to
	local from = effect.from
	local card = effect.card
	local max_card = self:getMaxCard()
	local cc = self.room:getCurrent()
	local ccmaxcard = self:getMaxCard(cc)
	if not self:hasTrickEffective(card, to, from) then return false end
	if not max_card then return false end
	if max_card <= ccmaxcard and not self:isFriend(cc) then return false end
	if self:doNotDiscard(cc, "h") and not self:isFriend(cc) and not self:isWeak() then return false end
	if card:isKindOf("FireAttack") then
		if to:isKongcheng() or from:isKongcheng() then return false end
	end
	if self:isFriend(to) and to:hasFlag("AIGlobal_NeedToWake") then return false end
	if from and not from:hasSkill("jueqing") then
		if (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("Drowning") or card:isKindOf("AOE")) and
			(to:hasSkill("wuyan") or (self:getDamagedEffects(to, from) and self:isFriend(to))) then
			return false
		end
		if (card:isKindOf("Duel") or card:isKindOf("Drowning") or card:isKindOf("AOE")) and not self:damageIsEffective(to, sgs.DamageStruct_Normal) then return false end --决斗、AOE 
		if card:isKindOf("FireAttack") and not self:damageIsEffective(to, sgs.DamageStruct_Fire) then return false end --火攻
	end 
	if (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("Drowning") or card:isKindOf("AOE")) and self:needToLoseHp(to, from) and self:isFriend(to) then
		return false
	end
	if ("snatch|dismantlement"):match(card:objectName()) and not to:containsTrick("YanxiaoCard") and (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) then
		if self:isEnemy(from) then return true end
		if self:isFriend(to) and to:isNude() then return false end
	end
		if card:getSkillName() == "lijian" and card:isKindOf("Duel") then
			if self:isFriend(to) and (self:isWeak(to) or not self:isWeak()) then return true end
			return
		end
		if card:isKindOf("ExNihilo") and (self:isWeak(from) or self:hasSkills(sgs.cardneed_skill, from) or from:hasSkill("manjuan")) and self:isEnemy(from) then return true end
		if card:isKindOf("IronChain") then return false end
		if self:isFriend(to) and not self:isEnemy(from) then
			if card:isKindOf("Dismantlement") then 
					if self:getDangerousCard(to) or self:getValuableCard(to) then return true end
					if to:getHandcardNum() == 1 and not self:needKongcheng(to) then
						if (getKnownCard(to, "TrickCard", false) == 1 or getKnownCard(to, "EquipCard", false) == 1 or getKnownCard(to, "Slash", false) == 1) then
							return false
						end
						return true
					end
			else
				if card:isKindOf("Snatch") then return true end
				if card:isKindOf("Duel") and not from:hasSkill("wuyan") and self:isWeak(to) then return true end
				if card:isKindOf("FireAttack") and from:objectName() ~= to:objectName() and not from:hasSkill("wuyan") then
						if from:getHandcardNum() > 2
							or self:isWeak(to)
							or to:hasArmorEffect("Vine")
							or to:getMark("@gale") > 0
							or to:isChained() and not self:isGoodChainTarget(to)
							then return true end
					end
				end
			elseif self:isEnemy(to) and not self:isFriend(from) then
				if (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and to:getCards("j"):length() > 0 then
					return true
			end
		end

		if card:isKindOf("AOE") and (self.player:objectName() == to:objectName() or self:isFriend(to)) then
			if self:hasSkills("jieming|yiji|guixin", self.player) and 
				(self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
						return false
			elseif not self:canAvoidAOE(card) then
					return true
			end
		end
		if self.player:objectName() == to:objectName():isKindOf("Duel") and not from:hasSkill("wuyan") and self.player:objectName() == to:objectName() then
			if self:hasSkills(sgs.masochism_skill, self.player) and 
						(self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
					return false
			elseif self:getCardsNum("Slash") == 0 then
					return true
			end
		end
		if from then
			if self:isEnemy(to) then
				if card:isKindOf("GodSalvation") and self:isWeak(to) then
					return true
				end
			end
		end
		if card:isKindOf("AmazingGrace") and self:isEnemy(to) then
			local NP = to:getNextAlive()
			if self:isFriend(NP) then
				local ag_ids = self.room:getTag("AmazingGrace"):toStringList()
				local peach_num, exnihilo_num, snatch_num, analeptic_num, crossbow_num = 0, 0, 0, 0, 0
				for _, ag_id in ipairs(ag_ids) do
					local ag_card = sgs.Sanguosha:getCard(ag_id)
					if ag_card:isKindOf("Peach") then peach_num = peach_num + 1 end
					if ag_card:isKindOf("ExNihilo") then exnihilo_num = exnihilo_num + 1 end
					if ag_card:isKindOf("Snatch") then snatch_num = snatch_num + 1 end
					if ag_card:isKindOf("Analeptic") then analeptic_num = analeptic_num + 1 end
					if ag_card:isKindOf("Crossbow") then crossbow_num = crossbow_num + 1 end
				end
				if (peach_num == 1 and to:getHp() < getBestHp(to)) or
					(peach_num > 0 and (self:isWeak(to) or NP:getHp() < getBestHp(NP) and self:getOverflow(NP) < 1)) then
					return true
				end
				if peach_num == 0 and not self:willSkipPlayPhase(NP) then
					if exnihilo_num > 0 then
						if NP:hasSkills("nosjizhi|jizhi|nosrende|rende|zhiheng") or NP:hasSkill("jilve") and NP:getMark("@bear") > 0 then return true end
					else
						for _, enemy in ipairs(self.enemies) do
							if snatch_num > 0 and to:distanceTo(enemy) == 1 and
								(self:willSkipPlayPhase(enemy, true) or self:willSkipDrawPhase(enemy, true)) then
								return true
							elseif analeptic_num > 0 and (self:isEquip("Axe", enemy) or self:getCardsNum("Axe", enemy) > 0) then
								return true
							elseif crossbow_num > 0 and getCardsNum("Slash", enemy) >= 3 then
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								for _, friend in ipairs(self.friends) do
									if enemy:distanceTo(friend) == 1 and self:slashIsEffective(slash, friend, nil, enemy) then
										return true
									end
								end
							end
						end
					end
				end
			end
		end
	return false 
end 



