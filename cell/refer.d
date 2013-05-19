module cell.refer;

import std.typecons;
import util.direct;
import util.array;
import cell.cell;
import cell.contentbox;
import cell.collection;
import cell.table;
debug(refer) import std.stdio;

// Viewの移動の際、
// 原点方向にはTableの中身をシフトする形で展開するが
// Cellの増加方向がPageViewの原点位置に来たときにTableを切り出す必要がある
// 他、Tableを切り出すとHolderになるし便利(そう)
// Tableの切り出しはTable自体でやる。Tableの外でするには干渉しすぎる。
class ReferTable : BoxTable{
private:
    BoxTable master; // almost all manipulation acts on this table
    Cell _offset;
    Cell _max_range; // table(master)の座標での取りうる最大値

    bool check_range(const Cell c)const{
        return  (c <=  _max_range);
    }
public:
    this(BoxTable attach, Cell ul,int w,int h)
        in{
        assert(attach !is null);
        assert(h>0);
        assert(w>0);
        }
    body{
        super();
        master = attach; // manipulating ReferBOX acts on attached Table
        set_range(ul,w,h);
    }
    unittest{
        import cell.textbox;
        auto table = new BoxTable();
        auto rtable = new ReferTable(table,Cell(3,3),8,8);
        assert(rtable._max_range == Cell(10,10));
        auto tb = new TextBOX(table);
        assert(tb.require_create_in(Cell(4,4)));
        auto items = rtable.get_content(Cell(1,1));
        assert(items[1] !is null);
        assert(tb.id == items[1].id);
        tb.require_expand(Direct.right);
        items = rtable.get_content(Cell(1,2));
        assert(items[1] !is null);
        auto all_items = rtable.get_contents();
        assert(all_items[0] == items);
        assert(tb.id == items[1].id);
        auto tb2 = new TextBOX(table);
        tb2.require_create_in(Cell(6,6));
    }
    auto get_contents(){
        return master.get_contents(_offset,_max_range);
    }
    override Tuple!(string,CellContent) get_content(const Cell c){
        return master.get_content(c+offset);
    }

    void set_range(Cell ul,int w,int h)
        in{
        assert(h>0);
        assert(w>0);
        }
    body{
        _offset = ul;
        auto row = _offset.row + h-1;
        auto col = _offset.column + w-1;
        _max_range = Cell(row,col);
        debug(refer) writefln("range h:%d w:%d",h,w);
    }
    // master のtableのなかでview に含まれるものを包めて返す
    // Contentの型情報はさらに落ちる
    override void add_box(T)(T u)
        in{
        assert(u.table == master);
        }
    body{
        if(!check_range) assert(0);
        master.add_box(u+_offset);
    }
    void move_area(in Direct to){
        _offset.move(to);
        _max_range.move(to);
    }
    @property Cell offset()const{
        return _offset;
    }
    Cell get_position(in CellContent b)const{
        assert(!b.empty());
        return b.top_left + _offset;
    }
    bool empty(){
        return master.empty();
    }
    void shift(in Direct dir){
        if(dir.is_positive)
            master.shift(dir);
        else
            move_area(dir);
    }
}




