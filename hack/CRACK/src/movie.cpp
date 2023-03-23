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
// physiscs
//================================================================================================================================

bool physics_ctor(physics *const body,  const double  x0, const double  y0,
                                        const double vx0, const double vy0,
                                        const double ax0, const double ay0,

                                        const double x_size,
                                        const double y_size,

                                        const int x_min,
                                        const int x_max,
                                        const int y_max)
{
    log_verify(body != nullptr, false);

    $x  =  x0; $y  =  y0;
    $vx = vx0; $vy = vy0;
    $ax = ax0; $ay = ay0;

    $x_size = x_size;
    $y_size = y_size;

    $x_min = x_min;
    $x_max = x_max;
    $y_max = y_max;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_simple_move(physics *const body, sf::Sprite *const body_spr)
{
    log_verify(body     != nullptr, false);
    log_verify(body_spr != nullptr, false);

    $x  += $vx; $y  += $vy;
    $vx += $ax; $vy += $ay;

    int x_int      = (int) $x;
    int x_int_size = (int) $x_size;
    int y_int      = (int) $y;
    int y_int_size = (int) $y_size;

    if      (x_int              > $x_max) { x_int = $x_min + (x_int - $x_max) % ($x_max - $x_min); $x = x_int; }
    else if (x_int              < $x_min) { x_int = $x_max - ($x_min - x_int) % ($x_max - $x_min); $x = x_int; }
    if      (y_int + y_int_size > $y_max) { y_int = $y_max - y_int_size;                           $y = y_int; }

    physics_reculc_accel(body);

    (*body_spr).setPosition($x, $y);

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_reculc_accel(physics *const body)
{
    log_verify(body != nullptr, false);

    if ((int) $y + (int) $y_size >= $y_max) $ay = 0;
    else                                    $ay = g;
    $ax = 0;

    return true;
}

//================================================================================================================================
// mario_handler
//================================================================================================================================

bool mario_ctor(mario_handler *const mario,
                const char    *const mario_file,
                const MOVE_DIRECTION mario_dir, const int    x_min          ,
                                                const int    x_max          , const int    y_max          ,
                                                const double x_size         , const double y_size         ,

                                                const double    x0          , const double    y0          ,
                                                const double   vx0 /* = 0 */, const double   vy0 /* = 0 */,
                                                const double   ax0 /* = 0 */, const double   ay0 /* = 0 */)
{
    log_verify(mario      != nullptr, false);
    log_verify(mario_file != nullptr, false);

    if (!$mario_tex.loadFromFile(mario_file))
    {
        log_error("Can't load mario texture from file \"%s\"\n", mario_file);
        return false;
    }

    sf::Vector2u size0 = $mario_tex.getSize();

    $mario_spr.setTexture ($mario_tex, true);
    $mario_spr.setScale   (x_size / (double) size0.x, y_size / (double) size0.y);
    $mario_tex.setPosition(x0, y0);

    $mario_dir = mario_dir;

    if (!physics_ctor(&$mario_kin, x0, y0, vx0, vy0, ax0, ay0, x_size, y_size, x_min, x_max, y_min)) return false;
    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_simple_move(mario_handler *const mario)
{
    log_verify(mario != nullptr, false);

    if      ($mario_dir == MOVE_RIGHT && $mario_kin.vx < 0) { $mario_spr.scale(-1.0, 1.0); $mario_dir = MOVE_LEFT;  }
    else if ($mario_dir == MOVE_LEFT  && $mario_kin.vx > 0) { $mario_spr.scale(-1.0, 1.0); $mario_dir = MOVE_RIGHT; }

    return physics_simple_move(&$mario_kin, &$mario_dir);
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_go_left(mario_handler *const mario, const double mario_speed)
{
    log_verify(mario != nullptr, false);

    $mario_kin.vx = (-1.0) * mario_speed;
    return true;
}

bool mario_go_right(mario_handler *const mario, const double mario_speed)
{
    log_verify(mario != nullptr, false);

    $mario_kin.vx = mario_speed;
    return true;
}

bool mario_jump(mario_handler *const mario, const double mario_speed)
{
    log_verify(mario != nullptr, false);

    if ((int) $mario_kin.y + (int) $mario_kin.y_size >= $mario_kin.y_max) $mario_kin.vy = (-1.0) * mario_speed;
    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_stop(mario_handler *const mario)
{
    log_verify(mario != nullptr, false);

    $mario_kin.vx = 0;
    return true;
}