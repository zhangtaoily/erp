package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdMaterialGroup;
import com.eerp.master.mapper.MdMaterialGroupMapper;
import com.eerp.master.service.MaterialGroupService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class MaterialGroupServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private MdMaterialGroupMapper mdMaterialGroupMapper;

    @InjectMocks private MaterialGroupService materialGroupService;

    private static final String BO_CODE = "MD_MATERIAL_GROUP";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存物料分组：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = materialGroupService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存物料分组数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = materialGroupService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用物料分组：更新enabled=1")
    void testEnable() {
        MdMaterialGroup group = new MdMaterialGroup();
        group.setId(ID);
        group.setEnabled(0);
        when(mdMaterialGroupMapper.selectById(ID)).thenReturn(group);

        materialGroupService.enable(ID);

        assertEquals(1, group.getEnabled());
        verify(mdMaterialGroupMapper).updateById(group);
    }

    @Test
    @DisplayName("查询物料分组详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = materialGroupService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询物料分组：委托 Mapper")
    void testFindById() {
        MdMaterialGroup group = new MdMaterialGroup();
        group.setId(ID);
        when(mdMaterialGroupMapper.selectById(ID)).thenReturn(group);

        MdMaterialGroup result = materialGroupService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
