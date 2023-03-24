#ifndef MOVIE_STATIC_H
#define MOVIE_STATIC_H

#include "movie.h"

//================================================================================================================================
// physiscs
//================================================================================================================================

#define $x      (physics_body). x
#define $vx     (physics_body).vx
#define $ax     (physics_body).ax

#define $y      (physics_body). y
#define $vy     (physics_body).vy
#define $ay     (physics_body).ay

#define $x_size (physics_body).x_size
#define $y_size (physics_body).y_size

static bool physics_ctor        (physics *const body, const double x_size,
                                                      const double y_size,  const double  x = 0, const double  y = 0,
                                                                            const double vx = 0, const double vy = 0,
                                                                            const double ax = 0, const double ay = 0);

static bool physics_set_param   (physics *const body,                       const double  x = 0, const double  y = 0,
                                                                            const double vx = 0, const double vy = 0,
                                                                            const double ax = 0, const double ay = 0);
static bool physics_simple_move (physics *const body);

//================================================================================================================================
// mario
//================================================================================================================================

#define $x_min      (mario_world_character).x_min
#define $x_max      (mario_world_character).x_max
#define $y_max      (mario_world_character).y_max

#define $kinematic  (mario_world_character).kinematic
#define $direction  (mario_world_character).direction

static bool mario_world_ctor(mario_world *const mario_life);
static bool mario_world_simple_move        (mario_world *const mario_life, sf::Sprite *const mario_sprite);
static bool mario_world_reculc_acceleration(mario_world *const mario_life);

static bool mario_world_go_left (mario_world *const mario_life);
static bool mario_world_go_right(mario_world *const mario_life);
static bool mario_world_jump    (mario_world *const mario_life);
static bool mario_world_stop    (mario_world *const mario_life);

//--------------------------------------------------------------------------------------------------------------------------------

#define $mario_tex  (mario_handler_exemplar).mario_tex
#define $mario_spr  (mario_handler_exemplar).mario_spr
#define $mario_life (mario_handler_exemplar).mario_life

static bool mario_handler_ctor(mario_handler *const mario, const char *const mario_file);

//================================================================================================================================
// render_text
//================================================================================================================================

#define $msg_font (render_text_str).message_font
#define $msg_text (render_text_str).message_text

static bool render_text_ctor(render_text *const str, const char *const   font_file,
                                                     const char *const     message,
                                                     const unsigned character_size,
                                                     const double x_pos,
                                                     const double y_pos);

//================================================================================================================================
// render_back
//================================================================================================================================

#define $back_tex (background).back_texture
#define $back_spr (background).back_sprite

static bool render_back_ctor(render_back *const ground, const char *const ground_file);

//================================================================================================================================
// sf::Music
//================================================================================================================================

static bool music_ctor(sf::Music *const music, const char *const music_file);

//================================================================================================================================
// crack_video
//================================================================================================================================

#define $music      (video).music
#define $rnd_text   (video).rnd_text
#define $rnd_back   (video).rnd_back
#define $hero       (video).hero

static bool crack_video_redraw_frame(crack_video *const crack, sf::RenderWindow *const wnd);

#endif //MOVIE_STATIC_H
