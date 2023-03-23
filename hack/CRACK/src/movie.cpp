#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "../../../lib_cpp/logs/log.h"
#include "../../../lib_cpp/algorithm/algorithm.h"

#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>

#include "movie.h"

//================================================================================================================================
// physics
//================================================================================================================================

#define physics_body (*body)

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_ctor(physics *const body,  const double x_size,
                                        const double y_size, const double  x /* = 0 */, const double  y /* = 0 */,
                                                             const double vx /* = 0 */, const double vy /* = 0 */,
                                                             const double ax /* = 0 */, const double ay /* = 0 */)
{
    log_assert(body != nullptr);

    $x_size = x_size;
    $y_size = y_size;

    return physics_set_param(x, y, vx, vy, ax, ay);
}

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_set_param(physics *const body, const double  x /* = 0 */, const double  y /* = 0 */,
                                            const double vx /* = 0 */, const double vy /* = 0 */,
                                            const double ax /* = 0 */, const double ay /* = 0 */)
{
    log_assert(body != nullptr);

    $x  =  x; $y  =  y;
    $vx = vx; $vy = vy;
    $ax = ax; $ay = ay;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_simple_move(physics *const body)
{
    log_assert(body != nullptr);

    $x  += $vx; $y  += $vy;
    $vx += $ax; $vy += $ay;

    return true;
}

//================================================================================================================================
// mario_world
//================================================================================================================================

#define mario_world_character (*mario_life)
#define physics_body          ( $kinematic)

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_ctor(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    physics_ctor(&$kinematic, MARIO_X_SIZE,
                              MARIO_Y_SIZE, 0, (double) WND_Y_SIZE - MARIO_Y_SIZE);
    $direction = MOVE_RIGHT;

    $x_min = 0;
    $x_max = WND_X_SIZE;
    $y_max = WND_Y_SIZE;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_simple_move(mario_world *const mario_life, sf::Sprite *const mario_sprite)
{
    log_verify(mario_life   != nullptr, false);
    log_verify(mario_sprite != nullptr, false);

    if      ($direction == MOVE_LEFT  && $vx > 0) { (*mario_sprite).setScale(-1.0, 1.0); $direction = MOVE_RIGHT; }
    else if ($direction == MOVE_RIGHT && $vx < 0) { (*mario_sprite).setScale(-1.0, 1.0); $direction = MOVE_LEFT;  }

    if (!physics_simple_move(&$kinematic)) return false;

    if      ((int) $x + (int) $x_size < $x_min) $x = $x_max;
    else if ((int) $x                 > $x_max) $x = $x_min;
    if      ((int) $y + (int) $y_size > $y_max) $y = $y_max - (int) $y_size;

    mario_sprite.setPosition($x, $y);

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_reculc_acceleration(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    if ((int) $y + (int) $y_size >= $y_max) $ay = 0;
    else                                    $ay = g;
    $ax = 0;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_go_left(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    $vx = (-1) * USER_SPEED;
    return true;
}

bool mario_world_go_right(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    $vx = USER_SPEED;
    return true;
}

bool mario_world_jump(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    if ((int) $y + (int) $y_size >= $y_max) $vy = (-1) * USER_JUMP;
    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_stop(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    $vx = 0;
    return true;
}

//================================================================================================================================
// mario_handler
//================================================================================================================================

#define mario_handler_exemplar  (*mario)
#define mario_world_caharacter  ($mario_life)
#define physics_body            ($kinematic )

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_handler_ctor(mario_handler *const mario)
{
    log_verify(mario != nullptr, false);

    if (!$mario_tex.loadFromFile(FILE_MARIO))
    {
        log_error("Can't load mario from file \"%s\"\n", FILE_MARIO);
        return false;
    }

    sf::Vector2u mario_initial_size = $mario_tex.getSize();

    $mario_spr.setTexture($mario_tex, true);
    $mario_spr.setScale  (MARIO_X_SIZE / (double) mario_initial_size.x, MARIO_Y_SIZE / (double) mario_initial_size.y);

    return mario_world_ctor(&$mario_life);
}

//--------------------------------------------------------------------------------------------------------------------------------
