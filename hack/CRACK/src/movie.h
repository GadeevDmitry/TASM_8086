#ifndef MOVIE_H
#define MOVIE_H

//================================================================================================================================
// CONST
//================================================================================================================================

extern const int WND_X_SIZE;
extern const int WND_Y_SIZE;

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
};

#define $x      (physics_body). x
#define $vx     (physics_body).vx
#define $ax     (physics_body).ax

#define $y      (physics_body). y
#define $vy     (physics_body).vy
#define $ay     (physics_body).ay

#define $x_size (physics_body).x_size
#define $y_size (physics_body).y_size

bool physics_ctor       (physics *const body, const double x_size,
                                              const double y_size,  const double  x = 0, const double  y = 0,
                                                                    const double vx = 0, const double vy = 0,
                                                                    const double ax = 0, const double ay = 0);

bool physics_set_param  (physics *const body,                       const double  x = 0, const double  y = 0,
                                                                    const double vx = 0, const double vy = 0,
                                                                    const double ax = 0, const double ay = 0);
bool physics_simple_move(physics *const body);

//================================================================================================================================
// mario
//================================================================================================================================

enum MOVE_DIRECTION
{
    MOVE_LEFT   ,
    MOVE_RIGHT  ,
};

//--------------------------------------------------------------------------------------------------------------------------------

struct mario_world
{
    int x_min, x_max;
    int y_max;

    physics        kinematic;
    MOVE_DIRECTION direction;
};

#define $x_min      (mario_world_character).x_min
#define $x_max      (mario_world_character).x_max
#define $y_max      (mario_world_character).y_max

#define $kinematic  (mario_world_character).kinematic
#define $direction  (mario_world_character).direction

bool mario_world_ctor               (mario_world *const mario_life);
bool mario_world_simple_move        (mario_world *const mario_life, sf::Sprite *const mario_sprite);
bool mario_world_reculc_acceleration(mario_world *const mario_life);

bool mario_world_go_left (mario_world *const mario_life);
bool mario_world_go_right(mario_world *const mario_life);
bool mario_world_jump    (mario_world *const mario_life);
bool mario_world_stop    (mario_world *const mario_life);

//--------------------------------------------------------------------------------------------------------------------------------

struct mario_handler
{
    sf::Texture mario_tex;
    sf::Sprite  mario_spr;
    mario_world mario_life;
};

#define $mario_tex  (mario_handler_exemplar).mario_tex
#define $mario_spr  (mario_handler_exemplar).mario_spr
#define $mario_life (mario_handler_exemplar).mario_life

bool mario_handler_ctor(mario_handler *const mario, const char *const mario_file);

//================================================================================================================================
// render_text
//================================================================================================================================

struct render_text
{
    sf::Font message_font;
    sf::Text message_text;
};

#define $msg_font (render_text_str).message_font
#define $msg_text (render_text_str).message_text

bool render_text_ctor       (render_text *const str, const char *const   font_file,
                                                     const char *const     message,
                                                     const unsigned character_size,
                                                     const double x_pos,
                                                     const double y_pos);

bool render_text_set_message (render_text *const str,   const char *const message);
bool render_text_progress_bar(render_text *const str, sf::RenderWindow *const wnd);

//================================================================================================================================
// render_back
//================================================================================================================================

struct render_back
{
    sf::Texture back_texture;
    sf::Sprite  back_sprite;
};

#define $back_tex (background).back_texture
#define $back_spr (background).back_sprite

bool render_back_ctor(render_back *const ground, const char *const ground_file);

//================================================================================================================================
// sf::Music
//================================================================================================================================

bool music_ctor(sf::Music *const music, const char *const music_file);

//================================================================================================================================
// crack_video
//================================================================================================================================

struct crack_video
{
    sf::Music     music;
    render_text   rnd_text;
    render_back   rnd_back;
    mario_handler hero;
};

#define $music      (video).music
#define $rnd_text   (video).rnd_text
#define $rnd_back   (video).rnd_back
#define $hero       (video).hero

bool crack_video_ctor  (crack_video *const crack, sf::RenderWindow *const wnd);
bool crack_video_window(crack_video *const crack, sf::RenderWindow *const wnd, buffer *const bin_code, const char *const out_file);

//================================================================================================================================
// MAIN
//================================================================================================================================

//--------------------------------------------------------------------------------------------------------------------------------
// verify
//--------------------------------------------------------------------------------------------------------------------------------

const unsigned long long CORRECT_HASH_VAL  = 0xFFFFFFFFFFFFFD1D;
const size_t             CORRECT_FILE_SIZE = 236;

bool get_file_to_crack   (buffer *const bin_code, const int argc, const char *argv[]);
bool is_correct_file_hash(buffer *const bin_code);

//--------------------------------------------------------------------------------------------------------------------------------
// patch
//--------------------------------------------------------------------------------------------------------------------------------

void patch(crack_video *const crack, sf::RenderWindow *const wnd, buffer *const bin_code, const char *const out_file);

#endif //MOVIE_H