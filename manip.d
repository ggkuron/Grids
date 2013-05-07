module manip;

import misc.direct;
import cell.textbox;
import cell.cell;
import command.command;
import gui.gui;
debug(manip) import std.stdio;

enum focus_mode{ normal,select,edit }

// 全てのCMDに対して
// 適切に捌く
// 全てのCMDを実行するためのハブ
// class Manipulater が存在してもいいかも
// 操作は細分化しているのに、それをCMDで全部捌いているのが問題だと思ったならそうすべき
// 複合的な操作は現在思いつかないのでこのままにする
// このコメントを消そうとするときに考えて欲しい

// Table に関する操作
   // ここからCellBOXに対する操作も行う
   // その責任は分離すべき
class ManipTable{
    BoxTable focused_table;
    ContentBOX manipulating_box;
    string box_type;

    ManipTextBOX manip_textbox;

    focus_mode mode;
    SelectBOX select;
    this(BoxTable table)
        out{
        assert(focused_table);
        assert(manip_textbox);
        assert(select);
        }
    body{
        focused_table = table;
        select = new SelectBOX(focused_table);

        manip_textbox = new ManipTextBOX(this);
    }
    void move_focus(Direct dir){
        import std.stdio;
        select.move(dir);
        debug(manip) writefln("focus: %s",select.focus);
    }
    void start_select()
        in{
        assert(mode != focus_mode.select);
        }
        out{
        assert(mode == focus_mode.select);
        }
    body{
        mode = focus_mode.select;
        select.set_pivot();
    }
    void select_clear(){
        select.clear();
    }
    // 端点にfocusがあればexpand, そうでなくてもfocusは動く
    final void expand_if_on_edge(Direct dir){
        if(select.is_on_edge(dir))
        {
            expand_select(dir);
        }
        move_focus(dir);
    }
    final void expand_to_focus()
        in{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
        out{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
    body{
        select.expand_to_focus();
    }
    void expand_select(Direct dir)
        in{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
        out{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
    body{
        select.expand(dir);
    }
    void return_to_normal_mode()
        in{
        assert(mode == focus_mode.select);
        }
        out{
        assert(mode == focus_mode.normal);
        }
    body{
        select.clear();
        mode = focus_mode.normal;
    }
    void start_insert_normal_text(){
        debug(manip) writeln("start_insert_normal_text");
        mode = focus_mode.edit;
        auto tb = select.create_TextBOX();

        manipulating_box = tb;
        focused_table.add_box!(TextBOX)(tb);
        writeln("type in: ",tb.toString());
        box_type = tb.toString();

        debug(manip) writeln("end");
    }
    void im_commit_str_send_to_box(string str){
        debug(manip) writeln("send to box start with :",str);
        switch(box_type){
            case "cell.textbox.TextBOX":
                manip_textbox.with_commit(str,cast(TextBOX)manipulating_box);
                return;
            default:
                break;
        }
    }
}

import gtk.IMMulticontext;
import gtk.IMContext;

class ManipTextBOX {
    ManipTable manip_table;
    IMMulticontext imm;
    this(ManipTable mt){
        manip_table = mt;
    }
    void move_caret(TextBOX box, Direct dir){
        final switch(dir){
            case Direct.right:
                box.move_caretR(); return;
                break;
            case Direct.left:
                box.move_caretL(); return;
                break;
            case Direct.up:
                box.move_caretU(); return;
                break;
            case Direct.down:
                box.move_caretD(); return;
                break;
        }
        assert(0);
    }
    void insert(TextBOX box,string str){
        debug(manip) writeln("text insert strat");
        box.insert(str);
        move_caret(box,Direct.right);
        // should move the focus on the table 
        //  acoording with caret positon
        debug(manip) writeln("end");
    }
    void with_commit(string str,TextBOX box){
        debug(manip) writeln("with commit text");
        insert(box,str);
    }
}
