#ifndef MOVIE_H
#define MOVIE_H

//================================================================================================================================
// CONST
//================================================================================================================================

const double g = 9.8;    // ускорение свободного падения

//================================================================================================================================
// physiscs
//================================================================================================================================

struct physics
{
    double  x,  y;
    double vx, vy;
    double ax, ay;

    double x_size;
    double y_size;

    int x_min, x_max;
    int y_max;
};

#define  $x     body-> x
#define $vx     body->vx
#define $ax     body->ax

#define  $y     body-> y
#define $vy     body->vy
#define $ay     body->ay

#define $x_size body->x_size
#define $y_size body->y_size

#define $x_min  body->x_min
#define $x_max  body->x_max
#define $y_max  body->y_max

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_ctor(physics *const body,  const double  x0, const double  y0,
                                        const double vx0, const double vy0,
                                        const double ax0, const double ay0,

                                        const double x_size,
                                        const double y_size,

                                        const int x_min,
                                        const int x_max,
                                        const int y_max);

bool physics_simple_move (physics *const body, sf::Sprite *const body_spr);
bool physics_reculc_accel(physics *const body);

//================================================================================================================================
// mario_handler
//================================================================================================================================

enum MOVE_DIRECTION
{
    MOVE_LEFT   ,
    MOVE_RIGHT  ,
};

struct mario_handler
{
    sf::Texture     mario_tex;
    sf::Sprite      mario_spr;
    physics         mario_kinematic;
    MOVE_DIRECTION  mario_direction;
};

#define $mario_tex  mario->mario_tex
#define $mario_spr  mario->mario_spr
#define $mario_kin  mario->mario_kinematic
#define $mario_dir  mario->mario_direction

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_ctor(mario_handler *const mario,
                const char    *const mario_file,
                const MOVE_DIRECTION mario_dir, const int    x_min      ,
                                                const int    x_max      , const int    y_max      ,
                                                const double x_size     , const double y_size     ,

                                                const double    x0      , const double    y0      ,
                                                const double   vx0 = 0.0, const double   vy0 = 0.0,
                                                const double   ax0 = 0.0, const double   ay0 = 0.0);

bool mario_simple_move(mario_handler *const mario);
bool mario_go_left    (mario_handler *const mario, const double mario_speed);
bool mario_go_right   (mario_handler *const mario, const double mario_speed);
bool mario_jump       (mario_handler *const mario, const double mario_speed);
bool mario_stop       (mario_handler *const mario);

//================================================================================================================================
// render_text
//================================================================================================================================

struct render_text
{
    sf::Font font;
    sf::Text text;
};

#define $font txt->font
#define $text txt->text

//--------------------------------------------------------------------------------------------------------------------------------

bool render_text_ctor(render_text *const txt, const char *const font_file,
                                              const char *const message,

                                              const double x_pos,
                                              const double y_pos);

bool render_text_upd_message(render_text *const txt, const char *const message);

//================================================================================================================================
// render_back
//================================================================================================================================

struct render_back
{
    sf::Texture back_texture;
    sf::Sprite  back_sprite;
};

#define $back_tex   back->back_texture
#define $back_spr   back->back_sprite

//--------------------------------------------------------------------------------------------------------------------------------

bool render_back_ctor(render_back *const back, const char *const back_file,

                                               const double x_size,
                                               const double y_size);

//================================================================================================================================
// crack_video
//================================================================================================================================

struct crack_video
{
    sf::Music   music;

    render_text   text;
    render_back   back;
    mario_handler hero;
};

#define $sound      crack->sound_track
#define $hero       crack->hero

//--------------------------------------------------------------------------------------------------------------------------------



#endif //MOVIE_H