///|
/// Maximum player health in hit points (20 points = ten hearts).
pub const MAX_HEALTH : Double = 20.0

///|
/// Maximum food level.
pub const MAX_HUNGER : Double = 20.0

///|
/// Maximum saturation carried over from food.
pub const MAX_SATURATION : Double = 5.0

///|
/// Seconds of breath before drowning damage begins.
pub const MAX_AIR : Double = 15.0

///|
/// Exhaustion accumulated before one saturation point is spent.
const EXHAUSTION_PER_SATURATION : Double = 4.0

///|
/// Hunger at or above which health naturally regenerates.
const REGEN_HUNGER_THRESHOLD : Double = 18.0

///|
/// Health restored per second while well fed.
const REGEN_PER_SECOND : Double = 0.5

///|
/// Fall distance that causes no damage.
const SAFE_FALL_DISTANCE : Double = 3.0

///|
/// Exhaustion gained per second while walking or sprinting.
const WALK_EXHAUSTION_PER_SECOND : Double = 0.05

///|
/// Additional exhaustion per second while sprinting.
const SPRINT_EXHAUSTION_PER_EXTRA : Double = 0.10

///|
/// Exhaustion added when a jump begins.
const JUMP_EXHAUSTION : Double = 0.2

///|
/// Damage per second while starving.
const STARVATION_PER_SECOND : Double = 0.25

///|
/// Damage per second once breath is exhausted underwater.
const DROWN_PER_SECOND : Double = 1.0

///|
/// Damage per second while the body is inside lava.
const LAVA_PER_SECOND : Double = 4.0

///|
/// Damage per second while touching a cactus.
const CACTUS_PER_SECOND : Double = 1.0

///|
/// Damage per second while below the world floor.
const VOID_PER_SECOND : Double = 4.0

///|
/// Seconds of immunity after a discrete hit lands.
const HURT_INVULNERABILITY : Double = 0.5

///|
/// Survival state for one player: hit points, food, breath, and timers.
pub struct Vitals {
  health : Double
  hunger : Double
  saturation : Double
  exhaustion : Double
  air : Double
  hurt_timer : Double
  dead : Bool
} derive(Debug, ToJson, FromJson)

///|
pub extend Vitals with Debug::{to_repr}

///|
pub extend Vitals with ToJson::{to_json}

///|
pub extend Vitals with FromJson::{from_json}

///|
/// The player's surroundings and motion for one survival tick.
struct VitalsContext {
  game_mode : String
  moved : Bool
  sprinted : Bool
  jumped : Bool
  on_ground : Bool
  fall_distance : Double
  head_in_water : Bool
  in_lava : Bool
  on_cactus : Bool
  below_world : Bool
} derive(Debug)

///|
pub extend VitalsContext with Debug::{to_repr}

///|
/// A full, healthy starting state.
pub fn Vitals::full() -> Vitals {
  {
    health: MAX_HEALTH,
    hunger: MAX_HUNGER,
    saturation: MAX_SATURATION,
    exhaustion: 0.0,
    air: MAX_AIR,
    hurt_timer: 0.0,
    dead: false,
  }
}

///|
fn in_survival_mode(game_mode : String) -> Bool {
  game_mode == "survival"
}

///|
fn Vitals::with_health(self : Vitals, health : Double) -> Vitals {
  let clamped = health.clamp(min=0.0, max=MAX_HEALTH)
  { ..self, health: clamped, dead: clamped <= 0.0, }
}

///|
/// Spend exhaustion on saturation, then hunger. Returns the updated triple.
fn drain_exhaustion(
  hunger : Double,
  saturation : Double,
  exhaustion : Double,
) -> (Double, Double, Double) {
  let steps = (exhaustion / EXHAUSTION_PER_SATURATION).floor()
  guard steps > 0.0 else { (hunger, saturation, exhaustion) }
  let from_saturation = steps.min(saturation)
  let from_hunger = steps - from_saturation
  (
    (hunger - from_hunger).max(0.0),
    saturation - from_saturation,
    exhaustion - steps * EXHAUSTION_PER_SATURATION,
  )
}

///|
/// Apply a discrete hit, respecting the post-hit invulnerability window.
fn Vitals::apply_hit(self : Vitals, amount : Double) -> Vitals {
  guard !self.dead else { self }
  guard amount > 0.0 else { self }
  guard self.hurt_timer <= 0.0 else { self }
  self.with_health(self.health - amount).with_hurt_timer(HURT_INVULNERABILITY)
}

///|
fn Vitals::with_hurt_timer(self : Vitals, seconds : Double) -> Vitals {
  { ..self, hurt_timer: seconds, }
}

///|
/// Apply damage that ignores the invulnerability window, such as drowning,
/// lava, cactus contact, void, or starvation.
fn Vitals::apply_continuous(self : Vitals, amount : Double) -> Vitals {
  guard !self.dead else { self }
  guard amount > 0.0 else { self }
  self.with_health(self.health - amount)
}

///|
/// Restore health without exceeding the maximum.
fn Vitals::heal(self : Vitals, amount : Double) -> Vitals {
  guard !self.dead else { self }
  { ..self, health: (self.health + amount).min(MAX_HEALTH), }
}

///|
/// Restore food from eating. No effect when dead or already full.
fn Vitals::eat(
  self : Vitals,
  nutrition : Double,
  saturation : Double,
) -> Vitals {
  guard !self.dead && self.hunger < MAX_HUNGER else { self }
  {
    ..self,
    hunger: (self.hunger + nutrition).min(MAX_HUNGER),
    saturation: (self.saturation + saturation).min(MAX_SATURATION),
  }
}

///|
/// Mark the player dead at zero health.
fn Vitals::kill(self : Vitals) -> Vitals {
  { ..self, health: 0.0, dead: true, }
}

///|
/// Advance hunger, regeneration, breath, and contact damage by `delta` seconds.
///
/// Creative and spectator players take no damage and always breathe. A dead
/// player stays dead until respawned.
fn Vitals::tick(self : Vitals, ctx : VitalsContext, delta : Double) -> Vitals {
  guard !self.dead else { self }
  guard in_survival_mode(ctx.game_mode) else {
    return { ..self, air: MAX_AIR, hurt_timer: 0.0, }
  }
  let added_exhaustion = WALK_EXHAUSTION_PER_SECOND * delta +
    (if ctx.sprinted { SPRINT_EXHAUSTION_PER_EXTRA * delta } else { 0.0 }) +
    (if ctx.jumped { JUMP_EXHAUSTION } else { 0.0 })
  let (hunger, saturation, exhaustion) = drain_exhaustion(
    self.hunger,
    self.saturation,
    self.exhaustion + added_exhaustion,
  )
  let mut next = { ..self, hunger, saturation, exhaustion, }
  if next.hunger >= REGEN_HUNGER_THRESHOLD && next.health < MAX_HEALTH {
    next = {
      ..next,
      health: (next.health + REGEN_PER_SECOND * delta).min(MAX_HEALTH),
    }
  }
  if next.hunger <= 0.0 {
    next = next.apply_continuous(STARVATION_PER_SECOND * delta)
  }
  if ctx.head_in_water {
    let air = (next.air - delta).max(0.0)
    next = { ..next, air, }
    if air <= 0.0 {
      next = next.apply_continuous(DROWN_PER_SECOND * delta)
    }
  } else {
    next = { ..next, air: MAX_AIR, }
  }
  if ctx.in_lava {
    next = next.apply_continuous(LAVA_PER_SECOND * delta)
  }
  if ctx.on_cactus {
    next = next.apply_continuous(CACTUS_PER_SECOND * delta)
  }
  if ctx.below_world {
    next = next.apply_continuous(VOID_PER_SECOND * delta)
  }
  if ctx.on_ground && ctx.fall_distance > SAFE_FALL_DISTANCE {
    next = next.apply_hit((ctx.fall_distance - SAFE_FALL_DISTANCE).floor())
  }
  { ..next, hurt_timer: (next.hurt_timer - delta).max(0.0), }
}
