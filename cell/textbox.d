module cell.textbox;

import cell.cell;
import cell.table;
import cell.contentbox;
import text.text;
import std.string;
import std.utf;
import util.direct;
import shape.shape;
debug(cell) import std.stdio;

// Text自体をTableに取り付けるためにBOX領域を管理する
final class TextBOX : ContentBOX{  
private:
    Text text;

    // このpublicはそのうちどっかに
    public int cursor_pos; // 描画側（IM)が教えるために使う
                           // こいつに関してはTextBOXは面倒見ない 
    public int font_size = 32;
    // 入力される文字色
    public Color font_color;

    string font_name = "Sans Normal";
    void insert_char(const dchar c){
        text.insert(c);
    }
public:
    this(BoxTable table){ 
        super(table);
    }
    this(BoxTable table,const Cell tl,const int w,const int h){
        super(table,tl,w,h);
    }
    this(BoxTable table,TextBOX tb){
        text = tb.text;
        cursor_pos = tb.cursor_pos;
        font_color = tb.font_color;
        super(table);
    }
    void set_color(in Color c){
        font_color = c;
        text.set_color(c);
    }
    void insert(string s){
        foreach(dchar c; s)
            text.insert(c);
    }
    void backspace(){
        if(!text.backspace())
            require_remove(Direct.down);
    }
    // userの意思でcaretを動かすとき
    bool move_caretR(){
        return text.move_caretR();
    }
    bool move_caretL(){
        return text.move_caretL();
    }
    bool move_caretD(){
        if(require_expand(Direct.down)
            && text.move_caretD())
        {
            debug(cell) writeln("expanded");
            return true;
        }else return false;
    }
    bool move_caretU(){
        return text.move_caretU();
    }
    void set_caret()(int pos){
        text.set_caret(pos); // 
    }
    // 操作が終わった時にTableから取り除くべきか
    // super.is_to_spoil()は強制削除のためにはかます必要がある
    override bool is_to_spoil()const{
        return super.is_to_spoil() || text.empty();
    }
    // アクセサ
    string get_fontname(){
        return font_name;
    }
    Text getText(){
        return text;
    }
}
