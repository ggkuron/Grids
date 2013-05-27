module gui.tableview;

import cell.cell;
import cell.contentbox;
import cairo.Context;
import util.color;
import util.direct;
import util.array;
import shape.shape;
import shape.drawer;

interface TableView{
    int get_gridSize()const;
    const(Rect) get_holdingArea()const;
    double get_x(in Cell c)const;
    double get_y(in Cell c)const;
final:
    // Cellの順ではなく、x(column方向),y(row方向)順なのに注意
    double[2] get_pos(in Cell c)const{
        return [get_x(c),get_y(c)]; 
    }
    // double[2] get_window_pos(in Cell c)const;
    double[2] get_window_pos(in Cell c)const{
        auto holding_area = get_holdingArea;
        return [get_x(c)+holding_area.x,get_y(c)+holding_area.y]; 
    }
    // Cellの座標と次のCellの座標、例えば入力Cell(5,5)に対してCell(5,5) とCell(6,6)の中間座標を返す
    // Cellに対する割り算には切り捨て方向に働きCell(5,5)/2 == Cell(2,2)になる。
    double[2] get_center_pos(in Cell c)const{
        immutable gridSpace = get_gridSize;
        return [get_x(c) + gridSpace/2, get_y(c) + gridSpace/2]; 
    }

    void FillCell(Context cr,in Cell cell,in Color grid_color){
        immutable gridSpace = get_gridSize();
        Rect grid_rect = new Rect(get_x(cell),get_y(cell),gridSpace,gridSpace);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.fill(cr);
    }
    void strokeGrids(Context cr,in Cell[] cells,in Color color,in ubyte grid_width){
        bool[Direct] adjacent_info(in Cell[] cells,in Cell searching){
            if(cells.empty) assert(0);
            bool[Direct] result;
            foreach(dir; Direct.min .. Direct.max+1){ result[cast(Direct)dir] = false; }

            foreach(a; cells)
            {
                if(a.column == searching.column)
                {   // adjacent to up or down
                    if(a.row == searching.row-1)  result[Direct.up] = true; else
                    if(a.row == searching.row+1)  result[Direct.down] = true;
                } 
                if(a.row == searching.row)
                {
                    if(a.column == searching.column-1) result[Direct.left] = true; else
                    if(a.column == searching.column+1) result[Direct.right] = true;
                }
            }
            return result;
        }
        if(cells.empty) return;

        Lines perimeters = new Lines;
        perimeters.set_color(color);
        perimeters.set_width(grid_width);

        foreach(c; cells)
        {
            const auto ad_info = adjacent_info(cells,c);
            foreach(n; Direct.min .. Direct.max+1 )
            {
                auto dir = cast(Direct)n;
                if(!ad_info[dir]){ // 隣接してない方向の境界を書く
                    perimeters.add_line(CellLine(c,dir,color,grid_width));
                }
            }
        }
        LinesDrawer drwer = new LinesDrawer(perimeters);
        drwer.stroke(cr);
    }
    Line CellLine(in Cell cell,in Direct dir,in Color color,double w){
        immutable gridSpace = get_gridSize();
        auto startp = new Point();
        auto endp = new Point();
        startp.x = get_x(cell);
        startp.y = get_y(cell);
        Line result;
        final switch(dir)
        {   
            case Direct.right:
                startp.x += gridSpace;
                endp.x = startp.x;
                endp.y = startp.y + gridSpace;
                break;
            case Direct.left:
                endp.x = startp.x;
                endp.y = startp.y + gridSpace;
                break;
            case Direct.up:
                endp.x = startp.x + gridSpace;
                endp.y = startp.y;
                break;
            case Direct.down:
                startp.y += gridSpace;
                endp.x = startp.x + gridSpace;
                endp.y = startp.y;
                break;
        }
        result = new Line(startp,endp);
        result.set_width(w);
        result.set_color(color);

        return result;
    }
    void FillGrids(Context cr,in Cell[] cells,in Color color){
        foreach(c; cells)
        {
            FillCell(cr,c,color);
        }
    }
    void FillBox(Context cr,in ContentBOX rb,in Color color){
        immutable top_left = rb.top_left();
        immutable gridSpace = get_gridSize();
        Rect grid_rect = new Rect(get_x(top_left), get_y(top_left), gridSpace*rb.numof_col, gridSpace*rb.numof_row);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(color);
        grid_drwer.fill(cr);
    }
    void StrokeBox(Context cr,const ContentBOX rb,const Color grid_color){
        immutable top_left = rb.top_left();
        immutable gridSpace = get_gridSize();
        Rect grid_rect = new Rect(get_x(top_left),get_y(top_left),gridSpace*rb.numof_col,gridSpace*rb.numof_row);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.stroke(cr);
    }

}