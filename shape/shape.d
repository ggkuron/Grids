module shape.shape;
// cairo wraper

// import deimos.cairo.cairo;
import cell.cell;
import std.string;
import cairo.ImageSurface;

struct Color{
    double r,g,b,a;
    // 初期値赤 初期化されてない色が存在しないように
    // 色という要素が存在するのなら初期化されない == 画面に出てはいけない
    this(double rr=255,double gg=0,double bb=0,double aa=255){
        r = rr; g = gg; b = bb; a = aa;
    }
    // this(SDL_Color c){
    //     r = c.g; g = c.g; b = c.b;
    // }
}
static white = Color(255,255,255,255);
static black = Color(0,0,0,255);
static red = Color(255,0,0,255);
    
class Shape{
    Color color;
    void attach(ContentBOX box){}
    void set_color(Color c= Color(255,255,255,255)){
        import std.stdio;
        color = c;
    }
    void scale(){}
}

class Point : Shape{
    double x,y;
    this(double xx=0, double yy=0){
        x = xx;
        y = yy;
    }
    this(int xx=0, int yy=0){
        x = xx;
        y = yy;
    }
}
class Line : Shape{
    Point start,end;
    double width;
    this(){}
    this(Point p1,Point p2){
        start = p1;
        end = p2;
    }
    this(Point p1,Point p2,double w){
        this(p1,p2);
        set_width(w);
    }
    void set_width(double w){
        width = w;
    }
}
        
class Lines : Line{
    Line[] lines;
    double width;
    this(){}
    Lines* opAssign(const Lines ls){ 
        lines = cast(Line[])ls.lines;
        width = ls.width;
        return cast(Lines*)this;
    }
    void set_width(double d){
        width = d;
    }
    void add_line(Line l){
        if(width != double.nan) l.set_width(width);
        l.set_color(color);
        lines ~= l;
    }
}
class Rect : Shape{
    double x,y,w,h;
    this(double xx=0,double yy=0,double ww=0,double hh=0){
        x = xx;
        y = yy;
        w = ww;
        h = hh;
    }
    this(Rect r){
        this = r;
    }
}
        
class Circle : Shape{
    Point p;
    double radius;
    this(Point x,double r){
        p = x;
        radius = r;
    }
}
class Arc : Circle{
    double from,to;
    this(Point x,double r,double angle1,double angle2){
        super(x,r);
        from = angle1;
        to = angle2;
    }
}
class Image : Shape{
    ImageSurface image;
    Rect frame;
    // double width,height; // if it were int and you want to scale Image, may cause droping 0 problem 
    this(string path,Rect f)
        out{
        assert(image);
        assert(frame);
        assert(frame.w > 0 && frame.h > 0);
        }
    body{
        image = ImageSurface.createFromPng(path);
        frame = f;
    }
    //  ~this(){ cairo_surface_destroy(image); }
}