/*
 * CPTableHeaderView.j
 * AppKit
 *
 * Created by Thomas Balthazar.
 * Copyright 2009, Suit My Mind, SPRL.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */
 
 
@import "CPControl.j"
@import "CPTableView.j"
@import "CPTableColumn.j"

@import "CPColor.j"
@import "CPTextField.j"

@implementation CPTableHeaderView : CPControl
{
    CPTableView _tableView;
    int         _resizedColumn;
}

- (CPTableView)tableView
{
    return _tableView ;
}

- (int)resizedColumn
{
    return _resizedColumn ;
}

- (int)draggedColumn {
    [CPException raise:CPUnsupportedMethodException reason:"Method not implemented yet : 'draggedColumn:'"];
    return -1;
}

- (float)draggedDistance {
    [CPException raise:CPUnsupportedMethodException reason:"Method not implemented yet : 'draggedDistance:'"];
    return -1;
}

- (void)setTableView:(CPTableView)aTableView
{
    _tableView = aTableView ;
}

- (CGRect)headerRectOfColumn:(int)aColumn {
    var tableColumns    = [_tableView tableColumns];
    var headerRect      = [self bounds];
    var spacing         = [_tableView intercellSpacing];
    var nbColumns       = [tableColumns count] ;

    if (aColumn < 0 || aColumn >= nbColumns) {
        [CPException raise:CPInternalInconsistencyException
                    reason:@"headerRectOfColumn: invalid index " + aColumn + " (valid {0, " + nbColumns + "})" ];
    }

    headerRect.size.width = [[tableColumns objectAtIndex:aColumn--] width] + spacing.width;
    while (aColumn >= 0)
        headerRect.origin.x += [[tableColumns objectAtIndex:aColumn--] width] + spacing.width;
    
    return headerRect;
}

- (int)columnAtPoint:(CGPoint)aPoint {
    var i, count = [[_tableView tableColumns] count];

    for (i = 0; i < count; ++i) {
        if (CGRectContainsPoint([self headerRectOfColumn:i], aPoint))
            return i;
    }

    return CPNotFound;
}

- (void)drawRect:(CGRect)aRect
{
    CPLog.warn("CPTableHeaderView : drawRect") ;
    var tableColumns    = [_tableView tableColumns];
    var count           = [tableColumns count];
    var columnRect      = [self bounds];
    var spacing         = [_tableView intercellSpacing];

    for (i = 0; i < count; ++i) {
        var column              = [tableColumns objectAtIndex:i];
        var headerView          = [column headerView] ;
        columnRect.size.width   = [column width] + spacing.width;
        // [headerView setHighlighted:[_tableView isColumnSelected:[[_tableView tableColumns] indexOfObject:column]]];
        [headerView setFrame:columnRect];
        columnRect.origin.x += [column width] + spacing.width;
        [_tableView addSubview:headerView] ;
    }
}

@end